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

import ZMCDataModel

extension ConversationContentViewController {

    /**
     Presents a `UIAlertController` of type action sheet with the options to delete a message everywhere, locally
     or to cancel. An optional completion block can be provided to get notified when an action has been selected.
     The delete everywhere option is only shown if this action is allowed for the input message.
     
     - parameter message:    The message for which the alert controller should be shown
     */
    func presentDeletionAlertController(forMessage message: ZMConversationMessage, completion: (() -> Void)?) {
        let showDelete = (message.sender?.isSelfUser ?? false) && conversation.isSelfAnActiveMember
        let alert = UIAlertController.alertControllerForMessageDeletion(showDelete) { [weak self] action in
            
            // Tracking needs to be called before performing the action, since the content of the message is cleared
            if case .Delete(let type) = action {
                self?.trackDelete(message, deletionType:type)

                ZMUserSession.sharedSession().enqueueChanges {
                    switch type {
                    case .Local:
                        ZMMessage.hideMessage(message)
                    case .Everywhere:
                        ZMMessage.deleteForEveryone(message)
                    }
                }
            }

            completion?()
            self?.dismissViewControllerAnimated(true, completion: nil)
        }

        if let presentationController = alert.popoverPresentationController,
            cell = cellForMessage(message) as? ConversationCell {
            presentationController.sourceView = cell.selectionView
            presentationController.sourceRect = cell.selectionRect
        }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func trackDelete(message: ZMConversationMessage, deletionType: AlertAction.DeletionType) {
        let conversationType: ConversationType = (conversation.conversationType == .Group) ? .Group : .OneToOne
        let messageType = Message.messageType(message)
        let timeElapsed = message.serverTimestamp?.timeIntervalSinceNow ?? 0
        Analytics.shared()?.tagDeletedMessage(messageType, messageDeletionType: deletionType.analyticsType, conversationType:conversationType, timeElapsed: 0 - timeElapsed)
    }

}

private enum AlertAction {
    enum DeletionType {
        case Local
        case Everywhere
        
        var analyticsType: MessageDeletionType {
            switch self {
            case .Local: return .Local
            case .Everywhere: return .Everywhere
            }
        }
    }
    
    case Delete(DeletionType), Cancel
}

private extension UIAlertController {

    static func alertControllerForMessageDeletion(showDelete: Bool, selectedAction: AlertAction -> Void) -> UIAlertController {
        let alertMessage = "message.delete_dialog.message".localized
        let alert = UIAlertController(title: nil, message: alertMessage, preferredStyle: .ActionSheet)

        let hideTitle = "message.delete_dialog.action.hide".localized
        let hideAction = UIAlertAction(title: hideTitle, style: .Default, handler: { _ in selectedAction(.Delete(.Local)) })
        alert.addAction(hideAction)

        if showDelete {
            let deleteTitle = "message.delete_dialog.action.delete".localized
            let deleteForEveryoneAction = UIAlertAction(title: deleteTitle, style: .Default, handler: { _ in selectedAction(.Delete(.Everywhere)) })
            alert.addAction(deleteForEveryoneAction)
        }

        let cancelTitle = "message.delete_dialog.action.cancel".localized
        let cancelAction = UIAlertAction(title: cancelTitle, style: .Cancel, handler: { _ in selectedAction(.Cancel)})
        alert.addAction(cancelAction)

        return alert
    }

}
