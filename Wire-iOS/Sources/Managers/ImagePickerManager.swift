//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import UIKit
import MobileCoreServices

private extension UIImage {

    var flattened: UIImage {
        if imageOrientation == .up { return self }

        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { _ in draw(at: .zero) }
    }

}

class ImagePickerManager: NSObject {

    // MARK: - Properties
    private var currentVC: UIViewController?
    private var sourceType: UIImagePickerController.SourceType?
    private var completion: ((UIImage) -> Void)?

    /// We need to store this reference to close the UIImagePickerController
    weak var presentingPickerController: UIImagePickerController?

    // MARK: - Methods
    func showActionSheet(vc: UIViewController?,
                         completion: @escaping (UIImage) -> Void) {
        self.currentVC = vc
        self.completion = completion

        let actionSheet = imagePickerAlert()
        currentVC?.present(actionSheet, animated: true)
    }

    private func imagePickerAlert() -> UIAlertController{
        typealias Alert = L10n.Localizable.Self.Settings.AccountPictureGroup.Alert
        let actionSheet = UIAlertController(title: Alert.title,
                                            message: nil,
                                            preferredStyle: .actionSheet)

        // Choose from gallery
        let galleryAction = UIAlertAction(title: Alert.choosePicture, style: .default) { [weak self] action -> Void in
            self?.sourceType = .photoLibrary
            self?.getImage(fromSourceType: .photoLibrary)
        }
        actionSheet.addAction(galleryAction)

        // Take photo
        let cameraAction = UIAlertAction(title: Alert.takePicture, style: .default) { [weak self] action -> Void in
            self?.sourceType = .camera
            self?.getImage(fromSourceType: .camera)
        }
        actionSheet.addAction(cameraAction)

        // Cancel
        actionSheet.addAction(.cancel())

        return actionSheet
    }

    private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {

        if UIImagePickerController.isSourceTypeAvailable(sourceType) || !UIImagePickerController.isCameraDeviceAvailable(.front) {

            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            imagePickerController.mediaTypes = [kUTTypeImage as String]

            switch sourceType {
            case .camera:
                imagePickerController.allowsEditing = true
                imagePickerController.cameraDevice = .front
                imagePickerController.modalTransitionStyle = .coverVertical
            case .photoLibrary, .savedPhotosAlbum:
                if let viewController = currentVC, viewController.isIPadRegular() {
                    imagePickerController.modalPresentationStyle = .popover

                    let popover: UIPopoverPresentationController? = imagePickerController.popoverPresentationController
                    popover?.backgroundColor = UIColor.white
                }
            default:
                break
            }

            currentVC?.present(imagePickerController, animated: true)
        }
    }

}

 extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

     public func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        presentingPickerController = picker
        guard let imageFromInfo = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }

        let image = imageFromInfo.flattened
        switch picker.sourceType {
        case .photoLibrary,
             .savedPhotosAlbum:

            let onConfirm: ConfirmAssetViewController.Confirm = { [weak self] editedImage in
                picker.dismiss(animated: true)
                self?.completion?(editedImage ?? image)
            }

            let onCancel: Completion = {
                picker.dismiss(animated: true)
            }

            let context = ConfirmAssetViewController.Context(asset: .image(mediaAsset: image),
                                                             onConfirm: onConfirm,
                                                             onCancel: onCancel)

            let confirmImageViewController = ConfirmAssetViewController(context: context)
            confirmImageViewController.modalPresentationStyle = .fullScreen

            picker.present(confirmImageViewController, animated: true)
            picker.setNeedsStatusBarAppearanceUpdate()

        case .camera:
            picker.dismiss(animated: true)
            completion?(image)
        @unknown default:
            picker.dismiss(animated: true)
            completion?(image)
        }

    }

}
