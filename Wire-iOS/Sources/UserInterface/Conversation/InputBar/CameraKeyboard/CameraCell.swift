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
    func cameraCellWantsToOpenFullCamera(_ cameraCell: CameraCell)
    func cameraCell(_ cameraCell: CameraCell, didPickImageData: Data)
}

open class CameraCell: UICollectionViewCell, Reusable {
    let cameraController: CameraController?
    
    let expandButton = IconButton()
    let takePictureButton = IconButton()
    let changeCameraButton = IconButton()
    
    weak var delegate: CameraCellDelegate?
    
    fileprivate static let ciContext = CIContext(options: [:])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        self.cameraController = CameraController()
        
        super.init(frame: frame)
        
        if let cameraController = self.cameraController {
            cameraController.previewLayer.frame = self.contentView.bounds
            cameraController.currentCamera = Settings.shared().preferredCamera
            cameraController.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.contentView.layer.addSublayer(cameraController.previewLayer)
        }
        
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = UIColor.black
        
        
        delay(0.01) {
            if let cameraController = self.cameraController {
                cameraController.startRunning()
            }
            self.updateVideoOrientation()
        }
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(cameraControllerWillChangeCurrentCamera(_:)), name: NSNotification.Name(rawValue: CameraControllerWillChangeCurrentCamera), object: .none)
        
        self.expandButton.setIcon(.fullScreen, with: .tiny, for: UIControlState())
        self.expandButton.setIconColor(UIColor.white, for: UIControlState())
        self.expandButton.translatesAutoresizingMaskIntoConstraints = false
        self.expandButton.addTarget(self, action: #selector(expandButtonPressed(_:)), for: .touchUpInside)
        self.expandButton.accessibilityIdentifier = "fullscreenCameraButton"
        self.contentView.addSubview(self.expandButton)
        
        self.takePictureButton.setIcon(.cameraShutter, with: .actionButton, for: UIControlState())
        self.takePictureButton.setIconColor(UIColor.white, for: UIControlState())
        self.takePictureButton.translatesAutoresizingMaskIntoConstraints = false
        self.takePictureButton.addTarget(self, action: #selector(shutterButtonPressed(_:)), for: .touchUpInside)
        self.takePictureButton.accessibilityIdentifier = "takePictureButton"
        self.contentView.addSubview(self.takePictureButton)
        
        self.changeCameraButton.setIcon(.cameraSwitch, with: .tiny, for: UIControlState())
        self.changeCameraButton.setIconColor(UIColor.white, for: UIControlState())
        self.changeCameraButton.translatesAutoresizingMaskIntoConstraints = false
        self.changeCameraButton.addTarget(self, action: #selector(changeCameraPressed(_:)), for: .touchUpInside)
        self.changeCameraButton.accessibilityIdentifier = "changeCameraButton"
        self.contentView.addSubview(self.changeCameraButton)
        
        [self.takePictureButton, self.expandButton, self.changeCameraButton].forEach { button in
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 0)
            button.layer.shadowRadius = 0.5
            button.layer.shadowOpacity = 0.5
        }
        
        constrain(self.contentView, self.expandButton, self.takePictureButton, self.changeCameraButton) { contentView, expandButton, takePictureButton, changeCameraButton in
            expandButton.width == 40
            expandButton.height == expandButton.width
            expandButton.right == contentView.right - 12
            expandButton.top == contentView.top + 10
            
            takePictureButton.width == 60
            takePictureButton.height == takePictureButton.width
            takePictureButton.bottom == contentView.bottom - 6
            takePictureButton.centerX == contentView.centerX
            
            changeCameraButton.width == 40
            changeCameraButton.height == changeCameraButton.width
            changeCameraButton.left == contentView.left + 12
            changeCameraButton.top == contentView.top + 10
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard let cameraController = self.cameraController else {
            return
        }
        
        if self.window == .none {
            cameraController.stopRunning()
        }
        else {
            cameraController.startRunning()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        guard let cameraController = self.cameraController else {
            return
        }
        cameraController.previewLayer.frame = self.contentView.bounds
        self.updateVideoOrientation()
    }
    
    fileprivate func updateVideoOrientation() {
        guard let cameraController = self.cameraController else {
            return
        }
        
        let newOrientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            newOrientation = .portrait;
            break;
        case .portraitUpsideDown:
            newOrientation = .portraitUpsideDown;
            break;
        case .landscapeLeft:
            newOrientation = .landscapeRight;
            break;
        case .landscapeRight:
            newOrientation = .landscapeLeft;
            break;
        default:
            newOrientation = .portrait;
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let connection = cameraController.previewLayer.connection,
                connection.isVideoOrientationSupported {
                connection.videoOrientation = newOrientation
            }
            
            cameraController.snapshotVideoOrientation = newOrientation
        }
        else {
            cameraController.snapshotVideoOrientation = .portrait
        }
    }
    
    func deviceOrientationDidChange(_ notification: Notification!) {
        self.updateVideoOrientation()
    }
    
    func cameraControllerWillChangeCurrentCamera(_ notification: Notification!) {
        
        guard let _ = self.window,
                let cameraController = self.cameraController,
                let snapshotImage = cameraController.videoSnapshot?.imageScaled(withFactor: 0.5) else {
            return
        }
    
        let blurredSnapshotImage = snapshotImage.blurredImage(with: type(of: self).ciContext, blurRadius: 12)
        
        let flipView = UIView()
        flipView.autoresizesSubviews = true
        flipView.frame = cameraController.previewLayer.frame
        flipView.backgroundColor = UIColor.black
        flipView.isOpaque = true
        self.contentView.insertSubview(flipView, belowSubview: self.expandButton)
        
        let unblurredImageView = UIImageView(image: snapshotImage)
        unblurredImageView.contentMode = .scaleAspectFill
        unblurredImageView.frame = flipView.bounds
        unblurredImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let blurredImageView = UIImageView(image: blurredSnapshotImage)
        blurredImageView.contentMode = .scaleAspectFill
        blurredImageView.frame = flipView.bounds
        blurredImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        flipView.addSubview(unblurredImageView)
        
        CATransaction.flush()
        
        cameraController.previewLayer.isHidden = true
        self.expandButton.isHidden = true
        self.takePictureButton.isHidden = true
        self.changeCameraButton.isHidden = true
        
        self.isUserInteractionEnabled = false
        
        UIView.transition(from: unblurredImageView, to: blurredImageView, duration: 0.35, options: .transitionFlipFromLeft) { _ in
        
            UIView.animate(withDuration: 0.35, delay: 0.35, options: [], animations: {
                    flipView.alpha = 0
                    cameraController.previewLayer.isHidden = false
                }, completion: { _ in
                    flipView.removeFromSuperview()

                    self.expandButton.isHidden = false
                    self.takePictureButton.isHidden = false
                    self.changeCameraButton.isHidden = false
                    self.isUserInteractionEnabled = true
            })
        }
        
    }
    
    // MARK: - Actions
    
    func expandButtonPressed(_ sender: AnyObject) {
        self.delegate?.cameraCellWantsToOpenFullCamera(self)
    }
    
    func shutterButtonPressed(_ sender: AnyObject) {
        guard let cameraController = self.cameraController else {
            return
        }
        
        cameraController.captureStillImage { data, meta, error in
            if error == nil {
                self.delegate?.cameraCell(self, didPickImageData: data!)
            }
        }
    }
    
    func changeCameraPressed(_ sender: AnyObject) {
        guard let cameraController = self.cameraController else {
            return
        }
        
        cameraController.currentCamera = cameraController.currentCamera == .front ? .back : .front
        Settings.shared().preferredCamera = cameraController.currentCamera
    }
}
