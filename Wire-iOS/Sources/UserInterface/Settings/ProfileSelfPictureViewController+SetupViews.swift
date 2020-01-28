//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import MobileCoreServices

extension ProfileSelfPictureViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        setupBottomOverlay()
        setupTopView()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    func addCameraButton() {
        cameraButton = IconButton()
        cameraButton.translatesAutoresizingMaskIntoConstraints = false

        bottomOverlayView.addSubview(cameraButton)
        
        var bottomOffset: CGFloat = 0.0
        if UIScreen.safeArea.bottom > 0 {
            bottomOffset = -UIScreen.safeArea.bottom + 20.0
        }

        cameraButton.alignCenter(to: bottomOverlayView, with: CGPoint(x:0, y:bottomOffset))

        cameraButton.setIconColor(.white, for: .normal)
        cameraButton.setIcon(.cameraLens, size: 40, for: .normal)
        cameraButton.addTarget(self, action: #selector(self.cameraButtonTapped(_:)), for: .touchUpInside)
        cameraButton.accessibilityLabel = "cameraButton"
    }

    func addCloseButton() {
        closeButton = IconButton()
        closeButton.accessibilityIdentifier = "CloseButton"

        bottomOverlayView.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setDimensions(length: 32)

        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            closeButton.rightAnchor.constraint(equalTo: bottomOverlayView.rightAnchor, constant: -18)
            ])

        closeButton.setIconColor(.white, for: .normal)
        closeButton.setIcon(.cross, size: .small, for: .normal)

        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for: .touchUpInside)
    }

    func addLibraryButton() {
        let length: CGFloat = 32
        let libraryButtonSize = CGSize(width: length, height: length)

        libraryButton = IconButton()
        libraryButton.translatesAutoresizingMaskIntoConstraints = false

        libraryButton.accessibilityIdentifier = "CameraLibraryButton"
        bottomOverlayView.addSubview(libraryButton)

        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.setDimensions(length: length)
        NSLayoutConstraint.activate([
            libraryButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            libraryButton.leftAnchor.constraint(equalTo: bottomOverlayView.leftAnchor, constant: 24)
            ])

        libraryButton.setIconColor(.white, for: .normal)
        libraryButton.setIcon(.photo, size: .small, for: .normal)

        if PHPhotoLibrary.authorizationStatus() == .authorized {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 1

            if let asset = PHAsset.fetchAssets(with: options).firstObject {
                // If asset is found, grab its thumbnail, create a CALayer with its contents,
                PHImageManager.default().requestImage(for: asset, targetSize: libraryButtonSize.applying(CGAffineTransform(scaleX: view.contentScaleFactor, y: view.contentScaleFactor)), contentMode: .aspectFill, options: nil, resultHandler: { result, info in
                    DispatchQueue.main.async(execute: {
                        self.libraryButton.imageView?.contentMode = .scaleAspectFill
                        self.libraryButton.contentVerticalAlignment = .center
                        self.libraryButton.contentHorizontalAlignment = .center
                        self.libraryButton.setImage(result, for: .normal)

                        self.libraryButton.layer.borderColor = UIColor.white.withAlphaComponent(0.32).cgColor
                        self.libraryButton.layer.borderWidth = 1
                        self.libraryButton.layer.cornerRadius = 5
                        self.libraryButton.clipsToBounds = true
                    })

                })
            }
        }

        libraryButton.addTarget(self, action: #selector(self.libraryButtonTapped(_:)), for: .touchUpInside)

    }

    open func setupTopView() {
        topView = UIView()
        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)

        topView.bottomAnchor.constraint(equalTo: bottomOverlayView.topAnchor).isActive = true
        topView.fitInSuperview(exclude: [.bottom])

        topView.backgroundColor = .clear

        selfUserImageView = UIImageView()
        selfUserImageView.clipsToBounds = true
        selfUserImageView.contentMode = .scaleAspectFill
        
        if let data = ZMUser.selfUser().imageMediumData {
            selfUserImageView.image = UIImage(data: data)
        }

        topView.addSubview(selfUserImageView)

        selfUserImageView.translatesAutoresizingMaskIntoConstraints = false
        selfUserImageView.fitInSuperview()
    }

    func setupBottomOverlay() {
        bottomOverlayView = UIView()
        bottomOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomOverlayView)

        var height: CGFloat
        // TODO: response to size class update
        if traitCollection.horizontalSizeClass == .regular {
            height = 104
        } else {
            height = 88
        }

        bottomOverlayView.fitInSuperview(exclude: [.top])
        bottomOverlayView.heightAnchor.constraint(equalToConstant: height + UIScreen.safeArea.bottom).isActive = true
        bottomOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)

        addCameraButton()
        addLibraryButton()
        addCloseButton()
    }

    @objc
    func libraryButtonTapped(_ sender: Any?) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        imagePickerController.delegate = imagePickerConfirmationController

        if isIPadRegular() {
            imagePickerController.modalPresentationStyle = .popover
            let popover: UIPopoverPresentationController? = imagePickerController.popoverPresentationController

            if let view = sender as? UIView {
                popover?.sourceRect = view.bounds.insetBy(dx: 4, dy: 4)
                popover?.sourceView = view
            }
            popover?.backgroundColor = UIColor.white
        }

        present(imagePickerController, animated: true)
    }

    @objc
    func cameraButtonTapped(_ sender: Any?) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) || !UIImagePickerController.isCameraDeviceAvailable(.front) {
            return
        }
        
        guard !CameraAccess.displayAlertIfOngoingCall(at:.takePhoto, from: self) else { return }
        
        let picker = UIImagePickerController()
        
        picker.sourceType = .camera
        picker.delegate = imagePickerConfirmationController
        picker.allowsEditing = true
        picker.cameraDevice = .front
        picker.mediaTypes = [kUTTypeImage as String]
        picker.modalTransitionStyle = .coverVertical
        present(picker, animated: true)
    }
}
