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

extension CameraBottomToolsViewController {
    func openPhotoLibrary(_ sender: Any) {
        let context = ImagePickerPopoverPresentationContext(sourceRect: libraryButton.bounds.insetBy(dx: 4, dy: 4),
                                                sourceView: libraryButton,
                                                presentViewController: self,
                                                sourceType: .photoLibrary)

        let picker = UIImagePickerController.popoverForIPadRegular(with: context)
        picker.delegate = imagePickerConfirmationController
        imagePickerConfirmationController.previewTitle = previewTitle
        present(picker, animated: true)
    }
}
