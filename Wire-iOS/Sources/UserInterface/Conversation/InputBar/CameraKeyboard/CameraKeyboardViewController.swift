//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 

import Photos
import AVFoundation
import UIKit
import WireSyncEngine

private let zmLog = ZMSLog(tag: "UI")

protocol CameraKeyboardViewControllerDelegate: class {
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo: URL, duration: TimeInterval)
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController,
                                      didSelectImageData: Data,
                                      isFromCamera: Bool,
                                      uti: String?)
    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController)
    func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController)
}

class CameraKeyboardViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    fileprivate var permissions: PhotoPermissionsController!
    fileprivate var lastLayoutSize = CGSize.zero
    fileprivate let collectionViewLayout = UICollectionViewFlowLayout()
    fileprivate let sideMargin: CGFloat = 14
    fileprivate var viewWasHidden: Bool = false
    fileprivate var callStateObserverToken: Any?
    fileprivate var goBackButtonRevealed: Bool = false {
        didSet {
            if goBackButtonRevealed {
                UIView.animate(withDuration: 0.35, animations: {
                    self.goBackButton.alpha = self.goBackButtonRevealed ? 1 : 0
                })
            } else {
                self.goBackButton.alpha = 0
            }
        }
    }
    fileprivate enum CameraKeyboardSection: UInt {
        case camera = 0, photos = 1
    }

    let assetLibrary: AssetLibrary?
    let imageManagerType: ImageManagerProtocol.Type

    var collectionView: UICollectionView!
    let goBackButton = IconButton()
    let cameraRollButton = IconButton()

    let splitLayoutObservable: SplitLayoutObservable
    weak var delegate: CameraKeyboardViewControllerDelegate?

    init(splitLayoutObservable: SplitLayoutObservable,
         imageManagerType: ImageManagerProtocol.Type = PHImageManager.self,
         permissions: PhotoPermissionsController = PhotoPermissionsControllerStrategy()) {
        self.splitLayoutObservable = splitLayoutObservable
        self.imageManagerType = imageManagerType
        self.assetLibrary = SecurityFlags.cameraRoll.isEnabled ? AssetLibrary() : nil
        self.permissions = permissions
        super.init(nibName: nil, bundle: nil)
        self.assetLibrary?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(splitLayoutChanged(_:)), name: NSNotification.Name.SplitLayoutObservableDidChangeToLayoutSize, object: self.splitLayoutObservable)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)

        if let userSession = ZMUserSession.shared() {
            self.callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.lastLayoutSize.equalTo(self.view.bounds.size) {
            self.lastLayoutSize = self.view.bounds.size
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification!) {
        self.assetLibrary?.refetchAssets()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        createConstraints()
    }

    private func setupViews() {
        self.createCollectionView()

        self.goBackButton.translatesAutoresizingMaskIntoConstraints = false
        self.goBackButton.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.goBackButton.circular = true
        self.goBackButton.setIcon(.backArrow, size: .tiny, for: [])
        self.goBackButton.setIconColor(UIColor.white, for: [])
        self.goBackButton.accessibilityIdentifier = "goBackButton"
        self.goBackButton.addTarget(self, action: #selector(goBackPressed(_:)), for: .touchUpInside)
        self.goBackButton.applyRTLTransformIfNeeded()

        self.cameraRollButton.translatesAutoresizingMaskIntoConstraints = false
        self.cameraRollButton.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.cameraRollButton.circular = true
        self.cameraRollButton.setIcon(.photo, size: .tiny, for: [])
        self.cameraRollButton.setIconColor(UIColor.white, for: [])
        self.cameraRollButton.accessibilityIdentifier = "cameraRollButton"
        self.cameraRollButton.addTarget(self, action: #selector(openCameraRollPressed(_:)), for: .touchUpInside)

        [self.collectionView, self.goBackButton, self.cameraRollButton].forEach(self.view.addSubview)
    }

    private func createConstraints() {
        [collectionView,
         goBackButton,
         cameraRollButton].prepareForLayout()

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            goBackButton.widthAnchor.constraint(equalToConstant: 36),
            goBackButton.widthAnchor.constraint(equalTo: goBackButton.heightAnchor),

            goBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideMargin),
            goBackButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(18 + UIScreen.safeArea.bottom)),

            cameraRollButton.widthAnchor.constraint(equalToConstant: 36),
            cameraRollButton.widthAnchor.constraint(equalTo: cameraRollButton.heightAnchor),
            cameraRollButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideMargin),
            cameraRollButton.centerYAnchor.constraint(equalTo: goBackButton.centerYAnchor)])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        if self.viewWasHidden {
            self.assetLibrary?.refetchAssets()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // For right-to-left layout first cell is at the far right corner.
        // We need to scroll to it when initially showing controller and it seems there is no other way...
        DispatchQueue.main.async {
            self.scrollToCamera(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewWasHidden = true
    }

    fileprivate func createCollectionView() {
        self.collectionViewLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        self.setupPhotoKeyboardAppearance()
        self.collectionView.register(CameraCell.self, forCellWithReuseIdentifier: CameraCell.reuseIdentifier)
        self.collectionView.register(AssetCell.self, forCellWithReuseIdentifier: AssetCell.reuseIdentifier)
        self.collectionView.register(CameraKeyboardPermissionsCell.self, forCellWithReuseIdentifier: CameraKeyboardPermissionsCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.bounces = false
    }

    func scrollToCamera(animated: Bool) {
        let endOfListX = UIApplication.isLeftToRightLayout ? 0 : self.collectionView.contentSize.width - 10
        self.collectionView.scrollRectToVisible(CGRect(x: endOfListX, y: 0, width: 10, height: 10), animated: animated)
    }

    @objc func goBackPressed(_ sender: AnyObject) {
        scrollToCamera(animated: true)
    }

    @objc func openCameraRollPressed(_ sender: AnyObject) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenCameraRoll(self)
    }

    @objc func splitLayoutChanged(_ notification: Notification!) {
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }

    fileprivate func forwardSelectedPhotoAsset(_ asset: PHAsset) {
        let completeBlock = { (data: Data?, uti: String?) in
            guard let data = data else { return }

            let returnData: Data
            if (uti == "public.heif") ||
                (uti == "public.heic"),
                let convertedJPEGData = data.convertHEIFToJPG() {
                returnData = convertedJPEGData
            } else {
                returnData = data
            }

            DispatchQueue.main.async(execute: {
                self.delegate?.cameraKeyboardViewController(self, didSelectImageData: returnData, isFromCamera: false, uti: uti)
            })
        }

        let limit = CGFloat.Image.maxSupportedLength
        if CGFloat(asset.pixelWidth) > limit || CGFloat(asset.pixelHeight) > limit {

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.resizeMode = .exact
            options.isSynchronous = false

            self.imageManagerType.defaultInstance.requestImage(for: asset, targetSize: CGSize(width: limit, height: limit), contentMode: .aspectFit, options: options, resultHandler: { image, info in
                if let image = image {
                    let data = image.jpegData(compressionQuality: 0.9)
                    completeBlock(data, info?["PHImageFileUTIKey"] as? String)
                } else {
                    options.isSynchronous = true
                    DispatchQueue.main.async(execute: {
                        self.isLoadingViewVisible = true
                    })

                    self.imageManagerType.defaultInstance.requestImage(for: asset, targetSize: CGSize(width: limit, height: limit), contentMode: .aspectFit, options: options, resultHandler: { image, info in
                        DispatchQueue.main.async(execute: {
                            self.isLoadingViewVisible = false
                        })

                        if let image = image {
                            let data = image.jpegData(compressionQuality: 0.9)
                            completeBlock(data, info?["PHImageFileUTIKey"] as? String)
                        } else {
                            zmLog.error("Failure: cannot fetch image")
                        }
                    })
                }

            })
        } else {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            self.imageManagerType.defaultInstance.requestImageData(for: asset, options: options, resultHandler: { data, uti, _, _ in

                guard let data = data else {
                    options.isNetworkAccessAllowed = true
                    DispatchQueue.main.async(execute: {
                        self.isLoadingViewVisible = true
                    })

                    self.imageManagerType.defaultInstance.requestImageData(for: asset, options: options, resultHandler: { data, uti, _, _ in
                        DispatchQueue.main.async(execute: {
                            self.isLoadingViewVisible = false
                        })
                        guard let data = data else {
                            zmLog.error("Failure: cannot fetch image")
                            return
                        }

                        completeBlock(data, uti)
                    })

                    return
                }

                completeBlock(data, uti)
            })
        }
    }

    fileprivate func forwardSelectedVideoAsset(_ asset: PHAsset) {
        isLoadingViewVisible = true
        guard let fileLengthLimit: UInt64 = ZMUserSession.shared()?.maxUploadFileSize else { return }

        asset.getVideoURL { url in
            DispatchQueue.main.async(execute: {
                self.isLoadingViewVisible = false
            })

            guard let url = url else { return }

            DispatchQueue.main.async(execute: {
                self.isLoadingViewVisible = true
            })

            AVURLAsset.convertVideoToUploadFormat(at: url, fileLengthLimit: Int64(fileLengthLimit)) { resultURL, asset, error in
                DispatchQueue.main.async(execute: {
                    self.isLoadingViewVisible = false
                })

                guard error == nil,
                    let resultURL = resultURL,
                    let asset = asset else { return }

                DispatchQueue.main.async(execute: {
                    self.delegate?.cameraKeyboardViewController(self, didSelectVideo: resultURL, duration: CMTimeGetSeconds(asset.duration))
                })
            }
        }

    }

    fileprivate func setupPhotoKeyboardAppearance() {

        if permissions.areCameraAndPhotoLibraryAuthorized {
            self.view.backgroundColor = .white
            self.collectionView.delaysContentTouches = true
        } else {
            self.view.backgroundColor = .graphite
            self.collectionView.delaysContentTouches = false
        }

        if permissions.isPhotoLibraryAuthorized {
            self.collectionViewLayout.minimumLineSpacing = 1
            self.collectionViewLayout.minimumInteritemSpacing = 0.5
            self.collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 1)
            self.cameraRollButton.isHidden = false
        } else {
            self.collectionViewLayout.minimumLineSpacing = 0
            self.collectionViewLayout.minimumInteritemSpacing = 0
            self.collectionViewLayout.sectionInset = .zero
            self.cameraRollButton.isHidden = true
        }
    }

}

extension CameraKeyboardViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        defer {
            setupPhotoKeyboardAppearance()
        }
        guard permissions.areCameraOrPhotoLibraryAuthorized else {
            return 1
        }
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard permissions.areCameraOrPhotoLibraryAuthorized else { return 1 }

        switch CameraKeyboardSection(rawValue: UInt(section))! {
        case .camera:
            return 1
        case .photos:
            guard let assetLibrary = assetLibrary else {
                return 1
            }
            return permissions.isPhotoLibraryAuthorized ? Int(assetLibrary.count) : 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard permissions.areCameraOrPhotoLibraryAuthorized else {
            return deniedAuthorizationCell(for: .cameraAndPhotos, collectionView: collectionView, indexPath: indexPath)
        }

        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:

            guard permissions.isCameraAuthorized else {
                return deniedAuthorizationCell(for: .camera, collectionView: collectionView, indexPath: indexPath)
            }

            if shouldBlockCallingRelatedActions {
                return deniedAuthorizationCell(for: .ongoingCall, collectionView: collectionView, indexPath: indexPath)
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCell.reuseIdentifier, for: indexPath) as! CameraCell
            cell.delegate = self
            return cell

        case .photos:

            guard permissions.isPhotoLibraryAuthorized else {
                return deniedAuthorizationCell(for: .photos, collectionView: collectionView, indexPath: indexPath)
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCell.reuseIdentifier, for: indexPath) as! AssetCell

            cell.manager = self.imageManagerType.defaultInstance

            if let asset = try? assetLibrary?.asset(atIndex: UInt((indexPath as NSIndexPath).row)) {
                cell.asset = asset
            }

            return cell
        }
    }

    /// TODO: a protocol for this for testing
    @objc
    var shouldBlockCallingRelatedActions: Bool {
        return ZMUserSession.shared()?.isCallOngoing ?? false
    }

    private func deniedAuthorizationCell(for type: DeniedAuthorizationType, collectionView: UICollectionView, indexPath: IndexPath) -> CameraKeyboardPermissionsCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraKeyboardPermissionsCell.reuseIdentifier,
                                                      for: indexPath) as! CameraKeyboardPermissionsCell
        cell.configure(deniedAuthorization: type)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard permissions.areCameraOrPhotoLibraryAuthorized else { return collectionView.frame.size }

        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            return cameraCellSize
        case .photos:
            guard permissions.isPhotoLibraryAuthorized else {
                return CGSize(width: self.view.bounds.size.width - cameraCellSize.width, height: self.view.bounds.size.height)
            }

            let photoSize = self.view.bounds.size.height / 2 - 0.5
            return CGSize(width: photoSize, height: photoSize)
        }
    }

    private var cameraCellSize: CGSize {
        switch self.splitLayoutObservable.layoutSize {
        case .compact:
            return CGSize(width: self.view.bounds.size.width / 2, height: self.view.bounds.size.height)
        case .regularPortrait, .regularLandscape:
            return CGSize(width: self.splitLayoutObservable.leftViewControllerWidth, height: self.view.bounds.size.height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard permissions.areCameraOrPhotoLibraryAuthorized else { return }

        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            break
        case .photos:
            guard
                permissions.isPhotoLibraryAuthorized,
                let asset = try? assetLibrary?.asset(atIndex: UInt((indexPath as NSIndexPath).row))
            else {
                return
            }

            switch asset.mediaType {
            case .video:
                self.forwardSelectedVideoAsset(asset)

            case .image:
                self.forwardSelectedPhotoAsset(asset)

            default:
                // not supported
                break
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is CameraCell || cell is CameraKeyboardPermissionsCell {
            self.goBackButtonRevealed = true
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is CameraCell || cell is CameraKeyboardPermissionsCell {
            self.goBackButtonRevealed = false

            (cell as? CameraCell)?.updateVideoOrientation()
        }
    }
}

extension CameraKeyboardViewController: CameraCellDelegate {
    func cameraCellWantsToOpenFullCamera(_ cameraCell: CameraCell) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenFullScreenCamera(self)
    }

    func cameraCell(_ cameraCell: CameraCell, didPickImageData imageData: Data) {
        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: imageData, isFromCamera: true, uti: nil)
    }
}

extension CameraKeyboardViewController: AssetLibraryDelegate {
    func assetLibraryDidChange(_ library: AssetLibrary) {
        self.collectionView.reloadData()
    }
}

extension CameraKeyboardViewController: WireCallCenterCallStateObserver {
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        /// TODO fix undesired camera keyboard openings here
        self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
    }
}

extension PHAsset {

    func getVideoURL(completionHandler : @escaping ((_ responseURL: URL?) -> Void)) {
        guard mediaType == .video else {
            completionHandler(nil)
            return
        }

        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, _: AVAudioMix?, _: [AnyHashable: Any]?) -> Void in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl: URL = urlAsset.url as URL
                completionHandler(localVideoUrl)
            } else {
                completionHandler(nil)
            }
        })
    }
}
