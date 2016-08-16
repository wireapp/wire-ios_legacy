//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


extension ConversationContentViewController {

    func presentDeletionAlertController(forMessage message: ZMConversationMessage) {
        let showDelete = message.sender?.isSelfUser ?? false && conversation.isSelfAnActiveMember
        let alert = UIAlertController.alertControllerForMessageDeletion(showDelete) { [weak self] action in
            ZMUserSession.sharedSession().enqueueChanges {
                switch action {
                case .Hide: ZMMessage.hideMessage(message)
                case .Delete: ZMMessage.deleteForEveryone(message)
                }
            }

            // TODO: Add tracking
            self?.dismissViewControllerAnimated(true, completion: nil)
        }

        if let presentationController = alert.popoverPresentationController,
            cell = cellForMessage(message) as? ConversationCell {
            presentationController.sourceView = cell.selectionView
            presentationController.sourceRect = cell.selectionRect
        }
        presentViewController(alert, animated: true, completion: nil)
    }

}

private enum DeleteAction {
    case Hide, Delete
}

private extension UIAlertController {

    static func alertControllerForMessageDeletion(showDelete: Bool, selectedAction: DeleteAction -> Void) -> UIAlertController {
        let alertMessage = "message.delete_dialog.message".localized
        let alert = UIAlertController(title: nil, message: alertMessage, preferredStyle: .ActionSheet)

        let hideTitle = "message.delete_dialog.action.hide".localized
        let hideAction = UIAlertAction(title: hideTitle, style: .Default, handler: { _ in selectedAction(.Hide) })
        alert.addAction(hideAction)

        if showDelete {
            let deleteTitle = "message.delete_dialog.action.delete".localized
            let deleteForEveryoneAction = UIAlertAction(title: deleteTitle, style: .Default, handler: { _ in selectedAction(.Delete) })
            alert.addAction(deleteForEveryoneAction)
        }

        let cancelTitle = "message.delete_dialog.action.cancel".localized
        let cancelAction = UIAlertAction(title: cancelTitle, style: .Cancel, handler: nil)
        alert.addAction(cancelAction)

        return alert
    }

}
