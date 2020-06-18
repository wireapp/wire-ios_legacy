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
import UIKit
import WireDataModel

extension ConversationContentViewController {
    // MARK: - EditMessages
    func editLastMessage() {
        if let lastEditableMessage = conversation.lastEditableMessage {
            perform(action: .edit, for: lastEditableMessage, view: tableView)
        }
    }

    func presentDetails(for message: ZMConversationMessage) {
        let isFile = Message.isFileTransfer(message)
        let isImage = Message.isImage(message)
        let isLocation = Message.isLocation(message)

        guard isFile || isImage || isLocation else {
            return
        }

        messagePresenter.open(message, targetView: tableView.targetView(for: message, dataSource: dataSource), actionResponder: self)
    }

    func openSketch(for message: ZMConversationMessage, in editMode: CanvasViewControllerEditMode) {
        let canvasViewController = CanvasViewController()
        if let imageData = message.imageMessageData?.imageData {
            canvasViewController.sketchImage = UIImage(data: imageData)
        }
        canvasViewController.delegate = self
        canvasViewController.title = message.conversation?.displayName.localizedUppercase
        canvasViewController.select(editMode: editMode, animated: false)

        present(canvasViewController.wrapInNavigationController(), animated: true)
    }

    func messageAction(actionId: MessageAction,
                       for message: ZMConversationMessage,
                       view: UIView) {
        switch actionId {
        case .cancel:
            session.enqueue({
                message.fileMessageData?.cancelTransfer()
            })
        case .resend:
            session.enqueue({
                message.resend()
            })
        case .delete:
            assert(message.canBeDeleted)

            deletionDialogPresenter = DeletionDialogPresenter(sourceViewController: presentedViewController ?? self)
            deletionDialogPresenter?.presentDeletionAlertController(forMessage: message, source: view) { deleted in
                if deleted {
                    self.presentedViewController?.dismiss(animated: true)
                }
            }
        case .present:
            dataSource.selectedMessage = message
            presentDetails(for: message)
        case .save:
            if Message.isImage(message) {
                saveImage(from: message, view: view)
            } else {
                dataSource.selectedMessage = message

                let targetView: UIView

                if let selectableView = view as? SelectableView {
                    targetView = selectableView.selectionView
                } else {
                    targetView = view
                }

                if let saveController = UIActivityViewController(message: message, from: targetView) {
                    present(saveController, animated: true)
                }
            }
        case .edit:
            dataSource.editingMessage = message
            delegate?.conversationContentViewController(self, didTriggerEditing: message)
        case .sketchDraw:
            openSketch(for: message, in: .draw)
        case .sketchEmoji:
            openSketch(for: message, in: .emoji)
        case .like, .unlike:
            // The new liked state, the value is flipped
            let updatedLikedState = !Message.isLikedMessage(message)
            guard let indexPath = dataSource.topIndexPath(for: message) else { return }

            let selectedMessage = dataSource.selectedMessage

            session.perform({
                Message.setLikedMessage(message, liked: updatedLikedState)
            })

            if updatedLikedState {
                // Deselect if necessary to show list of likers
                if selectedMessage == message {
                    willSelectRow(at: indexPath, tableView: tableView)
                }
            } else {
                // Select if necessary to prevent message from collapsing
                if !(selectedMessage == message) && !Message.hasReactions(message) {
                    willSelectRow(at: indexPath, tableView: tableView)

                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        case .forward:
            showForwardFor(message: message, from: view)
        case .showInConversation:
            scroll(to: message) { _ in
                self.dataSource.highlight(message: message)
            }
        case .copy:
            message.copy(in: .general)
        case .download:
            session.enqueue({
                message.fileMessageData?.requestFileDownload()
            })
        case .reply:
            delegate?.conversationContentViewController(self, didTriggerReplyingTo: message)

        case .openQuote:
            if let quote = message.textMessageData?.quote {
                scroll(to: quote) { _ in
                    self.dataSource.highlight(message: quote)
                }
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            parent?.present(detailsViewController, animated: true)
        }
    }
}
