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

public protocol CameraCellDelegate: class {
    func cameraCellWantsToOpenFullCamera(_ cameraCell: CameraCell)
    func cameraCell(_ cameraCell: CameraCell, didPickImageData: Data)
}

open class CameraCell: UICollectionViewCell {
    let cameraController: CameraController?
    
    let expandButton = IconButton()
    let takePictureButton = IconButton()
    let changeCameraButton = IconButton()
    
    weak var delegate: CameraCellDelegate?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init(frame: CGRect) {
        self.cameraController = CameraController(camera: Settings.shared().preferredCamera)

        super.init(frame: frame)
        
        if let cameraController = self.cameraController {
            cameraController.previewLayer.frame = self.contentView.bounds
            cameraController.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.contentView.layer.addSublayer(cameraController.previewLayer)
        }
        
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = UIColor.black
        
        delay(0.01) {
            self.cameraController?.startRunning()
            self.updateVideoOrientation()
        }
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: .none)
        
        self.expandButton.setIcon(.fullScreen, with: .tiny, for: [])
        self.expandButton.setIconColor(UIColor.white, for: [])
        self.expandButton.translatesAutoresizingMaskIntoConstraints = false
        self.expandButton.addTarget(self, action: #selector(expandButtonPressed(_:)), for: .touchUpInside)
        self.expandButton.accessibilityIdentifier = "fullscreenCameraButton"
        self.contentView.addSubview(self.expandButton)
        
        self.takePictureButton.setIcon(.cameraShutter, with: .cameraKeyboardButton, for: [])
        self.takePictureButton.setIconColor(UIColor.white, for: [])
        self.takePictureButton.translatesAutoresizingMaskIntoConstraints = false
        self.takePictureButton.addTarget(self, action: #selector(shutterButtonPressed(_:)), for: .touchUpInside)
        self.takePictureButton.accessibilityIdentifier = "takePictureButton"
        self.contentView.addSubview(self.takePictureButton)
        
        self.changeCameraButton.setIcon(.cameraSwitch, with: .tiny, for: [])
        self.changeCameraButton.setIconColor(UIColor.white, for: [])
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
        
        constrain(self.contentView, self.expandButton, self.takePictureButton, self.changeCameraButton) {
            contentView, expandButton, takePictureButton, changeCameraButton in
            expandButton.width == 40
            expandButton.height == expandButton.width
            expandButton.right == contentView.right - 12
            expandButton.top == contentView.top + 10
            
            takePictureButton.width == 60
            takePictureButton.height == takePictureButton.width
            takePictureButton.bottom == contentView.bottom - 6 - UIScreen.safeArea.bottom
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
        if self.window == .none { cameraController?.stopRunning() }
        else { cameraController?.startRunning() }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        cameraController?.previewLayer.frame = self.contentView.bounds
        self.updateVideoOrientation()
    }

    fileprivate func updateVideoOrientation() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        cameraController?.updatePreviewOrientation()
    }
    
    @objc func deviceOrientationDidChange(_ notification: Notification!) {
        self.updateVideoOrientation()
    }
    
    // MARK: - Actions
    
    @objc func expandButtonPressed(_ sender: AnyObject) {
        self.delegate?.cameraCellWantsToOpenFullCamera(self)
    }
    
    @objc func shutterButtonPressed(_ sender: AnyObject) {
        cameraController?.capturePhoto { data, error in
            if error == nil {
                self.delegate?.cameraCell(self, didPickImageData: data!)
            }
        }
    }
    
    @objc func changeCameraPressed(_ sender: AnyObject) {
        cameraController?.switchCamera { currentCamera in
            Settings.shared().preferredCamera = currentCamera
        }
    }
}
