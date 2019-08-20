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

extension ConversationInputBarViewController: UIDocumentPickerDelegate {

    @available(iOS 11.0, *)
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        uploadItem(at: url)
    }


    @available(iOS, introduced: 8.0, deprecated: 11.0, message: "Implement documentPicker:didPickDocumentsAtURLs: instead")
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        uploadItem(at: url)
    }

}

extension ConversationInputBarViewController {

    func configPopover(docController: UIDocumentPickerViewController,
                       sourceView: UIView,
                       delegate: UIPopoverPresentationControllerDelegate,
                       pointToView: UIView) {

        guard let popover = docController.popoverPresentationController else { return }

        popover.delegate = delegate
        popover.config(from: self, pointToView: pointToView, sourceView: sourceView)

        popover.permittedArrowDirections = .down
    }

    @objc
    func docUploadPressed(_ sender: IconButton) {
        mode = ConversationInputBarViewControllerMode.textInput
        inputBar.textView.resignFirstResponder()

        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
        documentPickerViewController.modalPresentationStyle = isIPadRegular() ? .popover : .fullScreen
        if isIPadRegular(),
            let sourceView = parent?.view,
            let pointToView = sender.imageView {
            configPopover(docController: documentPickerViewController, sourceView: sourceView, delegate: self, pointToView: pointToView)
        }

        documentPickerViewController.delegate = self

        parent?.present(documentPickerViewController, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }

}
