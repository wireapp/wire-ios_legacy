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

extension ConversationContentViewController: ConversationMessageCellDelegate {
    public func perform(action: MessageAction, for message: ZMConversationMessage!, sourceView: UIView!) {
        guard let selectableView = sourceView as? UIView & SelectableView else { return }

        wants(toPerform: action, for: message, cell: selectableView)
    }

    func conversationMessageWantsToOpenUserDetails(_ cell: UIView, user: UserType, sourceView: UIView, frame: CGRect) {
        delegate.didTap?(onUserAvatar: user, view: sourceView, frame: frame)
    }

    func conversationMessageShouldBecomeFirstResponderWhenShowingMenuForCell(_ cell: UIView) -> Bool {
        return delegate.conversationContentViewController(self, shouldBecomeFirstResponderWhenShowMenuFromCell: cell)
    }

    func conversationMessageWantsToOpenMessageDetails(_ cell: UIView, messageDetailsViewController: MessageDetailsViewController) {
        parent?.present(messageDetailsViewController, animated: true)
    }

    func conversationMessageWantsToOpenGuestOptionsFromView(_ cell: UIView, sourceView: UIView) {
        delegate.conversationContentViewController(self, presentGuestOptionsFrom: sourceView)
    }

    func conversationMessageWantsToOpenParticipantsDetails(_ cell: UIView, selectedUsers: [ZMUser], sourceView: UIView) {
        delegate.conversationContentViewController(self, presentParticipantsDetailsWithSelectedUsers: selectedUsers, from: sourceView)
    }

}

extension ConversationContentViewController: CanvasViewControllerDelegate {

}

extension ConversationContentViewController {
    func openSketch(for message: ZMConversationMessage, in editMode: CanvasViewControllerEditMode) {
        let canvasViewController = CanvasViewController()
        if let imageData = message.imageMessageData.imageData {
            canvasViewController.sketchImage = UIImage(data: imageData)
        }
        canvasViewController.delegate = self
        canvasViewController.title = message.conversation.displayName.uppercased()
        canvasViewController.select(with: editMode, animated: false)

        present(canvasViewController.wrapInNavigation(), animated: true)
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

            let indexPath: IndexPath? = dataSource?.indexPath(for: message)

            ZMUserSession.shared.performChanges({
                Message.setLiked(message, liked: liked)
            })

            if liked {
                // Deselect if necessary to show list of likers
                if dataSource?.selectedMessage == message {
                    if let indexPath = indexPath {
                        tableView(tableView, willSelectRowAt: indexPath)
                    }
                }
            } else {
                // Select if necessary to prevent message from collapsing
                if dataSource?.selectedMessage != message && !Message.hasReactions(message) {
                    if let indexPath = indexPath {
                        tableView(tableView, willSelectRowAt: indexPath)
                    }
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        case .forward:
            showForward(for: message, fromCell: cell)
        case ShowInConversation:
            scroll(to: message) { cell in
                self.dataSource?.highlight(message)
            }
        case .copy:
            Message.copy(message, in: UIPasteboard.general)
        case .download:
            ZMUserSession.sharedSession.enqueueChanges({
                message?.fileMessageData.requestFileDownload()
            })
        case .reply:
            delegate.conversationContentViewController(self, didTriggerReplyingTo: message)

        case .openQuote:
            if message?.textMessageData.quote != nil {
                let quote: ZMConversationMessage? = message?.textMessageData.quote
                scroll(to: quote) { cell in
                    self.dataSource?.highlight(quote)
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
    }
}
