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
    func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectVideo: AVURLAsset)
    func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectImageData: NSData, source: UIImagePickerControllerSourceType)
    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(controller: CameraKeyboardViewController)
    func cameraKeyboardViewControllerWantsToOpenCameraRoll(controller: CameraKeyboardViewController)
}


public class CameraKeyboardViewController: UIViewController {
    internal let assetLibrary: AssetLibrary
    
    private let collectionViewLayout = UICollectionViewFlowLayout()
    internal var collectionView: UICollectionView!
    
    internal let goBackButton = IconButton()
    internal let cameraRollButton = IconButton()
    private var lastLayoutSize = CGSizeZero
    
    private let sideMargin: CGFloat = 14
    
    private var goBackButtonRevealed: Bool = false {
        didSet {
            if goBackButtonRevealed {
                UIView.animateWithDuration(0.35) {
                    self.goBackButton.alpha = self.goBackButtonRevealed ? 1 : 0
                }
            }
            else {
                self.goBackButton.alpha = 0
            }
        }
    }
    
    public let splitLayoutObservable: SplitLayoutObservable
    
    private enum CameraKeyboardSection: UInt {
        case Camera = 0, Photos = 1
    }

    public weak var delegate: CameraKeyboardViewControllerDelegate?

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    init(splitLayoutObservable: SplitLayoutObservable, assetLibrary: AssetLibrary = AssetLibrary()) {
        self.splitLayoutObservable = splitLayoutObservable
        self.assetLibrary = assetLibrary
        super.init(nibName: nil, bundle: nil)
        self.assetLibrary.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(splitLayoutChanged(_:)), name: SplitLayoutObservableDidChangeToLayoutSizeNotification, object: self.splitLayoutObservable)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !CGSizeEqualToSize(self.lastLayoutSize, self.view.bounds.size) {
            self.lastLayoutSize = self.view.bounds.size
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
    
    @objc public func applicationDidBecomeActive(notification: NSNotification!) {
        self.assetLibrary.refetchAssets()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.createCollectionView()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.goBackButton.translatesAutoresizingMaskIntoConstraints = false
        self.goBackButton.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.goBackButton.circular = true
        self.goBackButton.setIcon(.BackArrow, withSize: .Tiny, forState: .Normal)
        self.goBackButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.goBackButton.accessibilityIdentifier = "goBackButton"
        self.goBackButton.addTarget(self, action: #selector(goBackPressed(_:)), forControlEvents: .TouchUpInside)
        
        self.cameraRollButton.translatesAutoresizingMaskIntoConstraints = false
        self.cameraRollButton.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.cameraRollButton.circular = true
        self.cameraRollButton.setIcon(.Photo, withSize: .Tiny, forState: .Normal)
        self.cameraRollButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.cameraRollButton.accessibilityIdentifier = "cameraRollButton"
        self.cameraRollButton.addTarget(self, action: #selector(openCameraRollPressed(_:)), forControlEvents: .TouchUpInside)
        
        [self.collectionView, self.goBackButton, self.cameraRollButton].forEach(self.view.addSubview)
        
        constrain(self.view, self.collectionView, self.goBackButton, self.cameraRollButton) { view, collectionView, goBackButton, cameraRollButton in
            collectionView.edges == view.edges
            
            goBackButton.width == 36
            goBackButton.height == goBackButton.width
            goBackButton.left == view.left + self.sideMargin
            goBackButton.bottom == view.bottom - 18
            
            cameraRollButton.width == 36
            cameraRollButton.height == goBackButton.width
            cameraRollButton.right == view.right - self.sideMargin
            cameraRollButton.centerY == goBackButton.centerY
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        DeviceOrientationObserver.sharedInstance().startMonitoringDeviceOrientation()
        self.assetLibrary.refetchAssets()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        DeviceOrientationObserver.sharedInstance().stopMonitoringDeviceOrientation()
    }
    
    private func createCollectionView() {
        self.collectionViewLayout.scrollDirection = .Horizontal
        self.collectionViewLayout.minimumLineSpacing = 1
        self.collectionViewLayout.minimumInteritemSpacing = 0.5
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 1)
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewLayout)
        self.collectionView.registerClass(CameraCell.self, forCellWithReuseIdentifier: CameraCell.reuseIdentifier)
        self.collectionView.registerClass(AssetCell.self, forCellWithReuseIdentifier: AssetCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.collectionView.bounces = false
    }
    
    func goBackPressed(sender: AnyObject) {
        self.collectionView.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated: true)
    }
    
    func openCameraRollPressed(sender: AnyObject) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenCameraRoll(self)
    }
    
    @objc func splitLayoutChanged(notification: NSNotification!) {
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }
    
    private func forwardSelectedPhotoAsset(asset: PHAsset) {
        let manager = PHImageManager.defaultManager()

        let options = PHImageRequestOptions()
        options.deliveryMode = .HighQualityFormat
        options.networkAccessAllowed = false
        options.synchronous = false
        manager.requestImageDataForAsset(asset, options: options, resultHandler: { data, uti, orientation, info in
            guard let data = data else {
                let options = PHImageRequestOptions()
                options.deliveryMode = .HighQualityFormat
                options.networkAccessAllowed = true
                options.synchronous = false
                dispatch_async(dispatch_get_main_queue(), {
                    self.showLoadingView = true
                })
                
                manager.requestImageDataForAsset(asset, options: options, resultHandler: { data, uti, orientation, info in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.showLoadingView = false
                    })
                    guard let data = data else {
                        DDLogError("Failure: cannot fetch image")
                        return
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: data, source: .PhotoLibrary)
                    })
                })
                
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.cameraKeyboardViewController(self, didSelectImageData: data, source: .PhotoLibrary)
            })
        })
    }
    
    private func forwardSelectedVideoAsset(asset: PHAsset) {
        let manager = PHImageManager.defaultManager()

        let options = PHVideoRequestOptions()
        options.deliveryMode = .HighQualityFormat
        options.networkAccessAllowed = true
        
        self.showLoadingView = true
        manager.requestAVAssetForVideo(asset, options: options, resultHandler: { videoAsset, audioMix, info in
            dispatch_async(dispatch_get_main_queue(), {
                self.showLoadingView = false
                guard let videoAsset = videoAsset as? AVURLAsset else {
                    return
                }
                
                self.delegate?.cameraKeyboardViewController(self, didSelectVideo: videoAsset)
            })
        })
    }
}


extension CameraKeyboardViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch CameraKeyboardSection(rawValue: UInt(section))! {
        case .Camera:
            return 1
        case .Photos:
            return Int(assetLibrary.count)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        switch CameraKeyboardSection(rawValue: UInt(indexPath.section))! {
        case .Camera:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CameraCell.reuseIdentifier, forIndexPath: indexPath) as! CameraCell
            cell.delegate = self
            return cell
        case .Photos:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AssetCell.reuseIdentifier, forIndexPath: indexPath) as! AssetCell
            cell.asset = try! assetLibrary.asset(atIndex: UInt(indexPath.row))
            return cell
        }
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        switch CameraKeyboardSection(rawValue: UInt(indexPath.section))! {
        case .Camera:
            switch self.splitLayoutObservable.layoutSize {
            case .Compact:
                return CGSizeMake(self.view.bounds.size.width / 2, self.view.bounds.size.height)
            case .RegularPortrait:
                fallthrough
            case .RegularLandscape:
                return CGSizeMake(self.splitLayoutObservable.leftViewControllerWidth, self.view.bounds.size.height)
            }
        case .Photos:
            let photoSize = self.view.bounds.size.height / 2 - 0.5
            return CGSizeMake(photoSize, photoSize)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        switch CameraKeyboardSection(rawValue: UInt(indexPath.section))! {
        case .Camera:
            break
        case .Photos:
            let asset = try! assetLibrary.asset(atIndex: UInt(indexPath.row))
            
            switch asset.mediaType {
            case .Video:
                self.forwardSelectedVideoAsset(asset)
            
            case .Image:
                self.forwardSelectedPhotoAsset(asset)
                
            default:
                // not supported
                break;
            }
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell is CameraCell {
            self.goBackButtonRevealed = true
        }
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell is CameraCell {
            self.goBackButtonRevealed = false
        }
    }
}


extension CameraKeyboardViewController: CameraCellDelegate {
    public func cameraCellWantsToOpenFullCamera(cameraCell: CameraCell) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenFullScreenCamera(self)
    }
    
    public func cameraCell(cameraCell: CameraCell, didPickImageData imageData: NSData) {
        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: imageData, source: .Camera)
    }
}

extension CameraKeyboardViewController: AssetLibraryDelegate {
    public func assetLibraryDidChange(library: AssetLibrary) {
        self.collectionView.reloadData()
    }
}
