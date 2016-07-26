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
import Cartography
import CoreImage

public protocol CameraCellDelegate: class {
    func cameraCellWantsToOpenFullCamera(cameraCell: CameraCell)
    func cameraCell(cameraCell: CameraCell, didPickImageData: NSData)
}

public class CameraCell: UICollectionViewCell {
    let cameraController = CameraController()
    
    let expandButton = IconButton()
    let takePictureButton = IconButton()
    let changeCameraButton = IconButton()
    
    weak var delegate: CameraCellDelegate?
    
    private static let ciContext = CIContext(options: [:])
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.cameraController.previewLayer.frame = self.contentView.bounds
        self.cameraController.currentCamera = Settings.sharedSettings().preferredCamera
            
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = UIColor.blackColor()
        
        self.cameraController.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.contentView.layer.addSublayer(self.cameraController.previewLayer)
        
        delay(0.01) {
            self.cameraController.startRunning()
            self.updateVideoOrientation()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(cameraControllerWillChangeCurrentCamera(_:)), name: CameraControllerWillChangeCurrentCamera, object: .None)
        
        self.expandButton.setIcon(.FullScreen, withSize: .Tiny, forState: .Normal)
        self.expandButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.expandButton.translatesAutoresizingMaskIntoConstraints = false
        self.expandButton.addTarget(self, action: #selector(expandButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.expandButton.accessibilityIdentifier = "fullscreenCameraButton"
        self.contentView.addSubview(self.expandButton)
        
        self.takePictureButton.setIcon(.CameraShutter, withSize: .ActionButton, forState: .Normal)
        self.takePictureButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.takePictureButton.translatesAutoresizingMaskIntoConstraints = false
        self.takePictureButton.addTarget(self, action: #selector(shutterButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.takePictureButton.accessibilityIdentifier = "takePictureButton"
        self.contentView.addSubview(self.takePictureButton)
        
        self.changeCameraButton.setIcon(.CameraSwitch, withSize: .Tiny, forState: .Normal)
        self.changeCameraButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.changeCameraButton.translatesAutoresizingMaskIntoConstraints = false
        self.changeCameraButton.addTarget(self, action: #selector(changeCameraPressed(_:)), forControlEvents: .TouchUpInside)
        self.changeCameraButton.accessibilityIdentifier = "changeCameraButton"
        self.contentView.addSubview(self.changeCameraButton)
        
        [self.takePictureButton, self.expandButton, self.changeCameraButton].forEach { button in
            button.layer.shadowColor = UIColor.blackColor().CGColor
            button.layer.shadowOffset = CGSizeMake(0.5, 0.5)
            button.layer.shadowRadius = 0.5
            button.layer.shadowOpacity = 0.5
        }
        
        constrain(self.contentView, self.expandButton, self.takePictureButton, self.changeCameraButton) { contentView, expandButton, takePictureButton, changeCameraButton in
            expandButton.width == 40
            expandButton.height == expandButton.width
            expandButton.right == contentView.right - 12
            expandButton.top == contentView.top + 12
            
            takePictureButton.width == 60
            takePictureButton.height == takePictureButton.width
            takePictureButton.bottom == contentView.bottom
            takePictureButton.centerX == contentView.centerX
            
            changeCameraButton.width == 40
            changeCameraButton.height == changeCameraButton.width
            changeCameraButton.left == contentView.left + 12
            changeCameraButton.top == contentView.top + 12
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window == .None {
            self.cameraController.stopRunning()
        }
        else {
            self.cameraController.startRunning()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.cameraController.previewLayer.frame = self.contentView.bounds
        self.updateVideoOrientation()
    }
    
    static var reuseIdentifier: String {
        return "\(self)"
    }
    
    override public var reuseIdentifier: String? {
        return self.dynamicType.reuseIdentifier
    }
    
    private func updateVideoOrientation() {
        let statusBarOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)!
        
        if let connection = self.cameraController.previewLayer.connection where connection.supportsVideoOrientation {
            connection.videoOrientation = statusBarOrientation
        }

        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.cameraController.snapshotVideoOrientation = statusBarOrientation
        }
        else {
            self.cameraController.snapshotVideoOrientation = .Portrait
        }
    }
    
    func cameraControllerWillChangeCurrentCamera(notification: NSNotification) {
        let snapshotImage = self.cameraController.videoSnapshot.imageScaledWithFactor(0.5)
    
        let blurredSnapshotImage = snapshotImage.blurredImageWithContext(self.dynamicType.ciContext, blurRadius: 12)
        
        let flipView = UIView()
        flipView.autoresizesSubviews = true
        flipView.frame = self.cameraController.previewLayer.frame
        flipView.backgroundColor = UIColor.blackColor()
        flipView.opaque = true
        self.contentView.insertSubview(flipView, belowSubview: self.expandButton)
        
        let unblurredImageView = UIImageView(image: snapshotImage)
        unblurredImageView.contentMode = .ScaleAspectFill
        unblurredImageView.frame = flipView.bounds
        unblurredImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        let blurredImageView = UIImageView(image: blurredSnapshotImage)
        blurredImageView.contentMode = .ScaleAspectFill
        blurredImageView.frame = flipView.bounds
        blurredImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        flipView.addSubview(unblurredImageView)
        
        CATransaction.flush()
        
        self.cameraController.previewLayer.hidden = true
        self.expandButton.hidden = true
        self.takePictureButton.hidden = true
        self.changeCameraButton.hidden = true
        
        self.userInteractionEnabled = false
        
        UIView.transitionFromView(unblurredImageView, toView: blurredImageView, duration: 0.35, options: .TransitionFlipFromLeft) { _ in
        
            UIView.animateWithDuration(0.35, delay: 0.35, options: [], animations: {
                    flipView.alpha = 0
                    self.cameraController.previewLayer.hidden = false
                }, completion: { _ in
                    flipView.removeFromSuperview()

                    self.expandButton.hidden = false
                    self.takePictureButton.hidden = false
                    self.changeCameraButton.hidden = false
                    self.userInteractionEnabled = true
            })
        }
        
    }
    
    // MARK: - Actions
    
    func expandButtonPressed(sender: AnyObject) {
        self.delegate?.cameraCellWantsToOpenFullCamera(self)
    }
    
    func shutterButtonPressed(sender: AnyObject) {
        self.cameraController.captureStillImageWithCompletionHandler { data, meta, error in
            if error == .None {
                self.delegate?.cameraCell(self, didPickImageData: data)
            }
        }
    }
    
    func changeCameraPressed(sender: AnyObject) {
        self.cameraController.currentCamera = self.cameraController.currentCamera == .Front ? .Back : .Front
        Settings.sharedSettings().preferredCamera = self.cameraController.currentCamera
    }
}
