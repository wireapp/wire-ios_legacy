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
import MobileCoreServices

extension ConversationInputBarViewController {

    func configPopover(docController: UIDocumentMenuViewController,
                             sourceView: UIView,
                             delegate: UIPopoverPresentationControllerDelegate,
                             pointToView: UIView) {
//    @objc
//    func configPopover(docController: UIDocumentPickerViewController,
//                       sourceView: UIView,
//                       delegate: UIPopoverPresentationControllerDelegate,
//                       pointToView: UIView) {

        guard let popover = docController.popoverPresentationController else { return }

        popover.delegate = delegate
        popover.config(from: self, pointToView: pointToView, sourceView: sourceView)

        popover.permittedArrowDirections = .down
    }

    @objc
    func docUploadPressed(_ sender: IconButton) {
        mode = ConversationInputBarViewControllerMode.textInput
        inputBar.textView.resignFirstResponder()

        let docController = UIDocumentMenuViewController(documentTypes: [kUTTypeItem as String], in: .import)
        docController.modalPresentationStyle = .popover
        docController.delegate = self

        //TODO:    #if (TARGET_OS_SIMULATOR)

        let movieMediaTypes = [kUTTypeMovie as String]

        docController.addOption(withTitle: "content.file.upload_video".localized,
                                image: UIImage.imageForIcon(.movie, size: 24, color: .darkGray), order: .first,
                                handler: {
            self.presentImagePicker(with: UIImagePickerController.SourceType.photoLibrary, mediaTypes: movieMediaTypes, allowsEditing: true, pointToView: self.videoButton.imageView)
        })

        docController.addOption(withTitle: "content.file.take_video".localized,
                                image: UIImage.imageForIcon(.cameraShutter, size: 24, color: .darkGray),
                                order: .first,
                                handler: {
            self.presentImagePicker(with: UIImagePickerController.SourceType.camera, mediaTypes: movieMediaTypes, allowsEditing: false, pointToView: self.videoButton.imageView)
        })

        if let sourceView = parent?.view, let pointToView = sender.imageView {
            configPopover(docController: docController, sourceView: sourceView, delegate: self, pointToView: pointToView)
        }

        parent?.present(docController, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }

}
