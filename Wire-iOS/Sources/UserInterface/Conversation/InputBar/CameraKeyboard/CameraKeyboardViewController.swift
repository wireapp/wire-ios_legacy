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


import Foundation
import Photos
import Cartography
import WireExtensionComponents
import CocoaLumberjackSwift
import AVFoundation

public protocol CameraKeyboardViewControllerDelegate: class {
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo: URL, duration: TimeInterval)
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData: Data, metadata: ImageMetadata)
    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController)
    func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController)
}


open class CameraKeyboardViewController: UIViewController {
    internal let assetLibrary: AssetLibrary
    
    fileprivate let collectionViewLayout = UICollectionViewFlowLayout()
    internal var collectionView: UICollectionView!
    
    internal let goBackButton = IconButton()
    internal let cameraRollButton = IconButton()
    fileprivate var lastLayoutSize = CGSize.zero
    
    fileprivate let sideMargin: CGFloat = 14
    
    fileprivate var viewWasHidden: Bool = false
    
    fileprivate var goBackButtonRevealed: Bool = false {
        didSet {
            if goBackButtonRevealed {
                UIView.animate(withDuration: 0.35, animations: {
                    self.goBackButton.alpha = self.goBackButtonRevealed ? 1 : 0
                }) 
            }
            else {
                self.goBackButton.alpha = 0
            }
        }
    }
    
    open let splitLayoutObservable: SplitLayoutObservable
    
    fileprivate enum CameraKeyboardSection: UInt {
        case camera = 0, photos = 1
    }

    open weak var delegate: CameraKeyboardViewControllerDelegate?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(splitLayoutObservable: SplitLayoutObservable, assetLibrary: AssetLibrary = AssetLibrary()) {
        self.splitLayoutObservable = splitLayoutObservable
        self.assetLibrary = assetLibrary
        super.init(nibName: nil, bundle: nil)
        self.assetLibrary.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(splitLayoutChanged(_:)), name: NSNotification.Name.SplitLayoutObservableDidChangeToLayoutSize, object: self.splitLayoutObservable)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.lastLayoutSize.equalTo(self.view.bounds.size) {
            self.lastLayoutSize = self.view.bounds.size
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
    
    @objc open func applicationDidBecomeActive(_ notification: Notification!) {
        self.assetLibrary.refetchAssets()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        createConstraints()
    }

    private func setupViews() {
        self.createCollectionView()

        self.view.backgroundColor = UIColor.white

        self.goBackButton.translatesAutoresizingMaskIntoConstraints = false
        self.goBackButton.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.goBackButton.circular = true
        self.goBackButton.setIcon(.backArrow, with: .tiny, for: UIControlState())
        self.goBackButton.setIconColor(UIColor.white, for: UIControlState())
        self.goBackButton.accessibilityIdentifier = "goBackButton"
        self.goBackButton.addTarget(self, action: #selector(goBackPressed(_:)), for: .touchUpInside)
        self.goBackButton.applyRTLTransformIfNeeded()

        self.cameraRollButton.translatesAutoresizingMaskIntoConstraints = false
        self.cameraRollButton.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.cameraRollButton.circular = true
        self.cameraRollButton.setIcon(.photo, with: .tiny, for: UIControlState())
        self.cameraRollButton.setIconColor(UIColor.white, for: UIControlState())
        self.cameraRollButton.accessibilityIdentifier = "cameraRollButton"
        self.cameraRollButton.addTarget(self, action: #selector(openCameraRollPressed(_:)), for: .touchUpInside)

        [self.collectionView, self.goBackButton, self.cameraRollButton].forEach(self.view.addSubview)
    }

    private func createConstraints() {
        constrain(self.view, self.collectionView, self.goBackButton, self.cameraRollButton) { view, collectionView, goBackButton, cameraRollButton in
            collectionView.edges == view.edges

            goBackButton.width == 36
            goBackButton.height == goBackButton.width
            goBackButton.leading == view.leading + self.sideMargin
            goBackButton.bottom == view.bottom - 18

            cameraRollButton.width == 36
            cameraRollButton.height == goBackButton.width
            cameraRollButton.trailing == view.trailing - self.sideMargin
            cameraRollButton.centerY == goBackButton.centerY
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        DeviceOrientationObserver.sharedInstance().startMonitoringDeviceOrientation()
        if self.viewWasHidden {
            self.assetLibrary.refetchAssets()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // For right-to-left layout first cell is at the far right corner.
        // We need to scroll to it when initially showing controller and it seems there is no other way...
        DispatchQueue.main.async {
            self.scrollToCamera(animated: false)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewWasHidden = true
        DeviceOrientationObserver.sharedInstance().stopMonitoringDeviceOrientation()
    }
    
    fileprivate func createCollectionView() {
        self.collectionViewLayout.scrollDirection = .horizontal
        self.collectionViewLayout.minimumLineSpacing = 1
        self.collectionViewLayout.minimumInteritemSpacing = 0.5
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 1)
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        self.collectionView.register(CameraCell.self, forCellWithReuseIdentifier: CameraCell.reuseIdentifier)
        self.collectionView.register(AssetCell.self, forCellWithReuseIdentifier: AssetCell.reuseIdentifier)
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
    
    func goBackPressed(_ sender: AnyObject) {
        scrollToCamera(animated: true)
    }
    
    func openCameraRollPressed(_ sender: AnyObject) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenCameraRoll(self)
    }
    
    @objc func splitLayoutChanged(_ notification: Notification!) {
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }
    
    fileprivate func forwardSelectedPhotoAsset(_ asset: PHAsset) {
        let manager = PHImageManager.default()

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        manager.requestImageData(for: asset, options: options, resultHandler: { data, uti, orientation, info in
            guard let data = data else {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                DispatchQueue.main.async(execute: {
                    self.showLoadingView = true
                })
                
                manager.requestImageData(for: asset, options: options, resultHandler: { data, uti, orientation, info in
                    DispatchQueue.main.async(execute: {
                        self.showLoadingView = false
                    })
                    guard let data = data else {
                        DDLogError("Failure: cannot fetch image")
                        return
                    }
                    
                    DispatchQueue.main.async(execute: {
                        let metadata = ImageMetadata()
                        metadata.camera = .none
                        metadata.method = ConversationMediaPictureTakeMethod.keyboard
                        metadata.source = ConversationMediaPictureSource.gallery
                        metadata.sketchSource = .none
                        
                        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: data, metadata: metadata)
                    })
                })
                
                return
            }
            DispatchQueue.main.async(execute: {
                
                let metadata = ImageMetadata()
                metadata.camera = .none
                metadata.method = ConversationMediaPictureTakeMethod.keyboard
                metadata.source = ConversationMediaPictureSource.gallery
                metadata.sketchSource = .none
                
                self.delegate?.cameraKeyboardViewController(self, didSelectImageData: data, metadata: metadata)
            })
        })
    }
    
    fileprivate func forwardSelectedVideoAsset(_ asset: PHAsset) {
        let manager = PHImageManager.default()

        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current

        self.showLoadingView = true
        manager.requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetMediumQuality) { exportSession, info in
            
            DispatchQueue.main.async(execute: {
            
                guard let exportSession = exportSession else {
                    self.showLoadingView = false
                    return
                }
                
                let exportURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("video-export.mp4"))
                
                if FileManager.default.fileExists(atPath: exportURL.path) {
                    do {
                        try FileManager.default.removeItem(at: exportURL)
                    }
                    catch let error {
                        DDLogError("Cannot remove \(exportURL): \(error)")
                    }
                }
                
                exportSession.outputURL = exportURL
                exportSession.outputFileType = AVFileTypeQuickTimeMovie
                exportSession.shouldOptimizeForNetworkUse = true
                exportSession.outputFileType = AVFileTypeMPEG4

                exportSession.exportAsynchronously {
                    self.showLoadingView = false
                    DispatchQueue.main.async(execute: {
                        self.delegate?.cameraKeyboardViewController(self, didSelectVideo: exportSession.outputURL!, duration: CMTimeGetSeconds(exportSession.asset.duration))
                    })
                }
            })
        }
    }
}


extension CameraKeyboardViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch CameraKeyboardSection(rawValue: UInt(section))! {
        case .camera:
            return 1
        case .photos:
            return Int(assetLibrary.count)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCell.reuseIdentifier, for: indexPath) as! CameraCell
            cell.delegate = self
            return cell
        case .photos:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCell.reuseIdentifier, for: indexPath) as! AssetCell
            if let asset = try? assetLibrary.asset(atIndex: UInt((indexPath as NSIndexPath).row)) {
                cell.asset = asset
            }
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            switch self.splitLayoutObservable.layoutSize {
            case .compact:
                return CGSize(width: self.view.bounds.size.width / 2, height: self.view.bounds.size.height)
            case .regularPortrait, .regularLandscape:
                return CGSize(width: self.splitLayoutObservable.leftViewControllerWidth, height: self.view.bounds.size.height)
            }
        case .photos:
            let photoSize = self.view.bounds.size.height / 2 - 0.5
            return CGSize(width: photoSize, height: photoSize)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            break
        case .photos:
            let asset = try! assetLibrary.asset(atIndex: UInt((indexPath as NSIndexPath).row))
            
            switch asset.mediaType {
            case .video:
                self.forwardSelectedVideoAsset(asset)
            
            case .image:
                self.forwardSelectedPhotoAsset(asset)
                
            default:
                // not supported
                break;
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is CameraCell {
            self.goBackButtonRevealed = true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is CameraCell {
            self.goBackButtonRevealed = false
        }
    }
}


extension CameraKeyboardViewController: CameraCellDelegate {
    public func cameraCellWantsToOpenFullCamera(_ cameraCell: CameraCell) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenFullScreenCamera(self)
    }
    
    public func cameraCell(_ cameraCell: CameraCell, didPickImageData imageData: Data) {
        guard let cameraController = cameraCell.cameraController else {
            return
        }
        
        let isFrontCamera = cameraController.currentCamera == .front
        
        let camera: ConversationMediaPictureCamera = isFrontCamera ? ConversationMediaPictureCamera.front : ConversationMediaPictureCamera.back
        
        let metadata = ImageMetadata()
        metadata.camera = camera
        metadata.method = ConversationMediaPictureTakeMethod.keyboard
        metadata.source = ConversationMediaPictureSource.camera
        metadata.sketchSource = .none
        
        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: imageData, metadata: metadata)
    }
}

extension CameraKeyboardViewController: AssetLibraryDelegate {
    public func assetLibraryDidChange(_ library: AssetLibrary) {
        self.collectionView.reloadData()
    }
}
