//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ProfilePictureStepViewController {

    @objc func showGalleryController(_ sender: Any) {
        let picker = UIImagePickerController()
        if #available(iOS 11.0, *) {
            picker.imageExportPreset = .compatible
        }

        picker.sourceType = .photoLibrary
        picker.delegate = self
        show(picker, inPopoverFrom: sender as? UIView)
    }
}

extension ProfilePictureStepViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @objc public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // For iOS 11, simply get single image form dictionary instead of PHImageManager, to get rid of photo access permission dialog
        if #available(iOS 11.0, *) {
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {

                self.dismiss(animated: true)
                return
            }

            self.profilePictureImageView.image = image
            self.setPictureImageData(image.jpegData(compressionQuality: 1.0))

            self.dismiss(animated: true)
        } else {
            UIImagePickerController.image(fromMediaInfo: info, resultBlock: { image in
                self.profilePictureImageView.image = image
            })
            UIImagePickerController.imageData(fromMediaInfo: info, resultBlock: { imageData in
                self.dismiss(animated: true)
                self.setPictureImageData(imageData)
            })
        }
    }

    @objc public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
}
