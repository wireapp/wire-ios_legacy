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

extension ProfileSelfPictureViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        setupBottomOverlay()
        setupTopView()
        setupGestureRecognizers()
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    @objc
    func addCameraButton() {
        cameraButton = ButtonWithLargerHitArea()
        cameraButton.translatesAutoresizingMaskIntoConstraints = false

        bottomOverlayView.addSubview(cameraButton)
        
        var bottomOffset: CGFloat = 0.0
        if UIScreen.safeArea.bottom > 0 {
            bottomOffset = -UIScreen.safeArea.bottom + 20.0
        }

        cameraButton.alignCenter(to: bottomOverlayView, with: CGPoint(x:0, y:bottomOffset))

        cameraButton.setImage(UIImage(for: .cameraLens, iconSize: .camera, color: .white), for: .normal)
        cameraButton.addTarget(self, action: #selector(self.cameraButtonTapped(_:)), for: .touchUpInside)
        cameraButton.accessibilityLabel = "cameraButton"
    }

    @objc
    func addCloseButton() {
        closeButton = ButtonWithLargerHitArea()
        closeButton.accessibilityIdentifier = "CloseButton"

        bottomOverlayView.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setDimensions(length: 32)

        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            closeButton.rightAnchor.constraint(equalTo: bottomOverlayView.rightAnchor, constant: -18)
            ])

        closeButton.setImage(UIImage(for: .X, iconSize: .small, color: .white), for: .normal)

        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for: .touchUpInside)
    }

    @objc
    func addLibraryButton() {
        let length: CGFloat = 32
        let libraryButtonSize = CGSize(width: length, height: length)

        libraryButton = ButtonWithLargerHitArea()
        libraryButton.translatesAutoresizingMaskIntoConstraints = false

        libraryButton.accessibilityIdentifier = "CameraLibraryButton"
        bottomOverlayView.addSubview(libraryButton)

        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.setDimensions(length: length)
        NSLayoutConstraint.activate([
            libraryButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            libraryButton.leftAnchor.constraint(equalTo: bottomOverlayView.leftAnchor, constant: 24)
            ])

        libraryButton.setImage(UIImage(for: .photo, iconSize: .small, color: .white), for: .normal)

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
        ///TODO: response to size class update
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


// MARK: - Gesture

    func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        topView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func didTap(_ gestureRecognizer: UITapGestureRecognizer?) {
        delegate.bottomOverlayViewControllerBackgroundTapped(self)
    }

}

