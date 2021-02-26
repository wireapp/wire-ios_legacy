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

import WireDataModel
import UIKit
import WireSyncEngine

private extension ZMConversationMessage {

    /// Whether the `Delete for everyone` option should be allowed and shown for this message.
    var canBeDeletedForEveryone: Bool {
        guard let sender = senderUser,
              let conversation = conversationLike else { return false }
        return sender.isSelfUser && conversation.isSelfAnActiveMember
    }

    var deletionConfiguration: DeletionConfiguration {
        // If the message failed to send we only want to show the delete for everyone option,
        // as we can not be sure that it did not hit the backend before we expired it.
        if deliveryState == .failedToSend {
            return .delete
        }

        return canBeDeletedForEveryone ? .hideAndDelete : .hide
    }

}

protocol SelectableView {
    var selectionView: UIView! { get }
    var selectionRect: CGRect { get }
}

protocol HighlightableView {
    var highlightContainer: UIView { get }
}

extension CollectionCell: SelectableView {
    public var selectionView: UIView! {
        return self
    }

    public var selectionRect: CGRect {
        return frame
    }
}

final class DeletionDialogPresenter: NSObject {

    private weak var sourceViewController: UIViewController?

    func deleteAlert(message: ZMConversationMessage,
                     sourceView: UIView?,
                     completion: ResultHandler? = nil) -> UIAlertController {
        let alert = UIAlertController.forMessageDeletion(with: message.deletionConfiguration) { (action, alert) in

            // Tracking needs to be called before performing the action, since the content of the message is cleared
            if case .delete(let type) = action {

                ZMUserSession.shared()?.enqueue({
                    switch type {
                    case .local:
                        ZMMessage.hideMessage(message)
                    case .everywhere:
                        ZMMessage.deleteForEveryone(message)
                    }
                }, completionHandler: {
                    completion?(true)
                })
            } else {
                completion?(false)
            }

            alert.dismiss(animated: true, completion: nil)
        }

        if let presentationController = alert.popoverPresentationController,
            let source = sourceView {
            if let selectableView = source as? SelectableView,
                selectableView.selectionView != nil {
                presentationController.sourceView = selectableView.selectionView
                presentationController.sourceRect = selectableView.selectionRect
            } else {
                alert.configPopover(pointToView: source, popoverPresenter: sourceViewController as? PopoverPresenterViewController)
            }
        }

        return alert
    }

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
        super.init()
    }

    /**
     Presents a `UIAlertController` of type action sheet with the options to delete a message everywhere, locally
     or to cancel. An optional completion block can be provided to get notified when an action has been selected.
     The delete everywhere option is only shown if this action is allowed for the input message.
     
     - parameter message: The message for which the alert controller should be shown.
     - parameter source: The source view used for a potential popover presentation of the dialog.
     - parameter completion: A completion closure which will be invoked with `true` if a deletion occured and `false` otherwise.
     */
    func presentDeletionAlertController(forMessage message: ZMConversationMessage, source: UIView?, completion: ResultHandler?) {
        guard !message.hasBeenDeleted else { return }

        let alert = deleteAlert(message: message,
                                sourceView: source,
                                completion: completion)
        sourceViewController?.present(alert, animated: true)
    }
}

private enum AlertAction {
    enum DeletionType {
        case local
        case everywhere
    }

    case delete(DeletionType), cancel
}

// Used to enforce only valid configurations can be shown.
// Unfortunately this can not be done with an `OptionSetType`
// as there is no way to enforce a non-empty option set.
private enum DeletionConfiguration {
    case hide, delete, hideAndDelete

    var showHide: Bool {
        switch self {
        case .hide, .hideAndDelete: return true
        case .delete: return false
        }
    }

    var showDelete: Bool {
        switch self {
        case .delete, .hideAndDelete: return true
        case .hide: return false
        }
    }
}

private extension UIAlertController {

    static func forMessageDeletion(with configuration: DeletionConfiguration, selectedAction: @escaping (AlertAction, UIAlertController) -> Void) -> UIAlertController {
        let alertTitle = "message.delete_dialog.message".localized
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)

        if configuration.showHide {
            let hideTitle = "message.delete_dialog.action.hide".localized
            let hideAction = UIAlertAction(title: hideTitle, style: .destructive) { [unowned alert] _ in selectedAction(.delete(.local), alert) }
            alert.addAction(hideAction)
        }

        if configuration.showDelete {
            let deleteTitle = "message.delete_dialog.action.delete".localized
            let deleteForEveryoneAction = UIAlertAction(title: deleteTitle, style: .destructive) { [unowned alert] _ in selectedAction(.delete(.everywhere), alert) }
            alert.addAction(deleteForEveryoneAction)
        }

        let cancelTitle = "message.delete_dialog.action.cancel".localized
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { [unowned alert] _ in selectedAction(.cancel, alert) }
        alert.addAction(cancelAction)

        return alert
    }

}
