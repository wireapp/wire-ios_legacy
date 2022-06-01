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
import WireSystem
import UIKit
import WireSyncEngine

private let zmLog = ZMSLog(tag: "Drag and drop images")

extension ConversationInputBarViewController: UIDropInteractionDelegate, PerformClipboardAction {

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {

        for dragItem in session.items {
            let itemProvider = dragItem.itemProvider
            if itemProvider.hasText() {
                itemProvider.loadObject(ofClass: NSString.self) { [self] object, _ in
                    guard let draggedText = object as? String else { return }
                    DispatchQueue.main.async {
                        self.inputBar.textView.text = draggedText
                    }
                }
            } else if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { object, error in

                    guard error == nil else { return zmLog.error("Failed to load dragged item: \(error!.localizedDescription)") }
                    guard let draggedImage = object as? UIImage else { return }

                    DispatchQueue.main.async {
                        let context = ConfirmAssetViewController.Context(asset: .image(mediaAsset: draggedImage),
                                                                         onConfirm: { [unowned self] _ in
                                                                            self.dismiss(animated: true) {
                                                                                if let draggedImageData = draggedImage.pngData() {
                                                                                    self.sendController.sendMessage(withImageData: draggedImageData)
                                                                                }
                                                                            }
                                                                         },
                                                                         onCancel: { [unowned self] in
                                                                            self.dismiss(animated: true)
                                                                         }
                        )

                        let confirmImageViewController = ConfirmAssetViewController(context: context)
                        confirmImageViewController.previewTitle = self.conversation.displayName.localizedUppercase
                        self.present(confirmImageViewController, animated: true) {
                        }
                    }
                })

                // TODO: it's a temporary solution to drag only one image, while we have no design for multiple images
                break
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return dropProposal(isText: session.hasText(),
                            isClipboardEnabled: SecurityFlags.clipboard.isEnabled,
                            canFilesBeShared: MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).canCopyFromClipboard)
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func dropProposal(isText: Bool, isClipboardEnabled: Bool, canFilesBeShared: Bool) -> UIDropProposal {
      return shouldAllowPerformAction(isText: isText, isClipboardEnabled: isClipboardEnabled, canFilesBeShared: canFilesBeShared)
        ? UIDropProposal(operation: .copy)
        : UIDropProposal(operation: .forbidden)
    }

}

private extension UIDropSession {

    func hasText() -> Bool {
        // Image dragged from browser can be both NSString and UIImage
        return canLoadObjects(ofClass: NSString.self) && !canLoadObjects(ofClass: UIImage.self)
    }

}

private extension NSItemProvider {

    func hasText() -> Bool {
        // Image dragged from browser can be both NSString and UIImage
        return canLoadObject(ofClass: NSString.self) && !canLoadObject(ofClass: UIImage.self)
    }

}
