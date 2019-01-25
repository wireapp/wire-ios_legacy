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


extension ConversationContentViewController {
    func openSketch(for message: ZMConversationMessage, in editMode: CanvasViewControllerEditMode) {
        let canvasViewController = CanvasViewController()
        if let imageData = message.imageMessageData?.imageData {
            canvasViewController.sketchImage = UIImage(data: imageData)
        }
        canvasViewController.delegate = self
        canvasViewController.title = message.conversation?.displayName.uppercased()
        canvasViewController.select(editMode: editMode, animated: false)

        present(canvasViewController.wrapInNavigationController(), animated: true)
    }


    private func messageAction(actionId: MessageAction,
                               for message: ZMConversationMessage,
                               cell: (UIView & SelectableView)?) {
        guard let session = ZMUserSession.shared() else { return }

        switch actionId {
        case .cancel:
            session.enqueueChanges({
                message.fileMessageData?.cancelTransfer()
            })
        case .resend:
            session.enqueueChanges({
                message.resend()
            })
        case .delete:
            assert(message.canBeDeleted)

            self.deletionDialogPresenter = DeletionDialogPresenter(sourceViewController: self.presentedViewController ?? self)
            self.deletionDialogPresenter.presentDeletionAlertController(forMessage: message, source: cell) { deleted in
                if deleted {
                    self.presentedViewController?.dismiss(animated: true)
                }
                if !deleted {
                    // TODO 2838: Support editing
                    // cell.beingEdited = NO;
                }
            }
        case .present:
            self.dataSource?.selectedMessage = message
            self.presentDetails(for: message)
        case .save:
            if Message.isImage(message) {
                self.saveImage(from: message, cell: cell)
            } else {
                self.dataSource?.selectedMessage = message
                if let targetView: UIView = cell?.selectionView,
                    let saveController = UIActivityViewController(message: message, from: targetView) {
                    self.present(saveController, animated: true)
                }
            }
        case .edit:
            dataSource?.editingMessage = message
            delegate.conversationContentViewController(self, didTriggerEditing: message)
        case .sketchDraw:
            openSketch(for: message, in: .draw)
        case .sketchEmoji:
            openSketch(for: message, in: .emoji)
        case .sketchText:
            // Not implemented yet
            break
        case .like:
            let liked = !Message.isLikedMessage(message)

            if let indexPath = dataSource?.indexPath(for: message),
                let selectedMessage = dataSource?.selectedMessage {

                session.performChanges({
                    Message.setLikedMessage(message, liked: liked)
                })

                if liked {
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
            }
        case .forward:
            showForwardFor(message: message, fromCell: cell)
        case .showInConversation:
            scroll(to: message) { cell in
                self.dataSource?.highlight(message: message)
            }
        case .copy:
            Message.copy(message, in: UIPasteboard.general)
        case .download:
            session.enqueueChanges({
                message.fileMessageData?.requestFileDownload()
            })
        case .reply:
            delegate.conversationContentViewController(self, didTriggerReplyingTo: message)

        case .openQuote:
            if let quote = message.textMessageData?.quote {
                scroll(to: quote) { cell in
                    self.dataSource?.highlight(message: quote)
                }
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            parent?.present(detailsViewController, animated: true)
        }
    }

    func wants(toPerform actionId: MessageAction,
               for message: ZMConversationMessage,
               cell: (UIView & SelectableView)?) {


        let shouldDismissModal: Bool = actionId != .delete && actionId != .copy

        if messagePresenter.modalTargetController?.presentedViewController != nil && shouldDismissModal {
            messagePresenter.modalTargetController?.dismiss(animated: true) {
                self.messageAction(actionId: actionId,
                                   for: message,
                                   cell: cell)
            }
        } else {
            messageAction(actionId: actionId,
                          for: message,
                          cell: cell)
        }
    }}
