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

@objc protocol ActionController: NSObjectProtocol {
    var alertController: UIAlertController? {get}
    func presentMenu(from sourceView: UIView?, showConverationNameInMenuTitle: Bool)
}

extension ActionController {
    private func prepare(viewController: UIViewController, with context: PresentationContext) {
        viewController.popoverPresentationController.apply {
            $0.sourceView = context.view
            $0.sourceRect = context.rect
        }
    }

    func present(_ controller: UIViewController,
                 currentContext: PresentationContext?,
                 target: UIViewController) {
        currentContext.apply {
            prepare(viewController: controller, with: $0)
        }
        target.present(controller, animated: true, completion: nil)
    }

}

struct PresentationContext {
    let view: UIView
    let rect: CGRect
}

@objcMembers final class ConversationActionController: NSObject, ActionController {

    private let conversation: ZMConversation
    unowned let target: UIViewController
    var currentContext: PresentationContext?
    weak var alertController: UIAlertController?
    
    @objc init(conversation: ZMConversation, target: UIViewController) {
        self.conversation = conversation
        self.target = target
        super.init()
    }

    func presentMenu(from sourceView: UIView?, showConverationNameInMenuTitle: Bool = true) {
        currentContext = sourceView.map {
            .init(
                view: target.view,
                rect: target.view.convert($0.frame, from: $0.superview).insetBy(dx: 8, dy: 8)
            )
        }
        
        let controller = UIAlertController(title: showConverationNameInMenuTitle ? conversation.displayName: nil, message: nil, preferredStyle: .actionSheet)
        // TODO: we need to exclude the notification settings action if the menu is being presented from the conversation details.
        conversation.actions.map(alertAction).forEach(controller.addAction)
        controller.addAction(.cancel())
        present(controller)

        alertController = controller
    }
    
    func enqueue(_ block: @escaping () -> Void) {
        ZMUserSession.shared()?.enqueueChanges(block)
    }
    
    func transitionToListAndEnqueue(_ block: @escaping () -> Void) {
        ZClientViewController.shared()?.transitionToList(animated: true) {
            ZMUserSession.shared()?.enqueueChanges(block)
        }
    }

    func handleAction(_ action: ZMConversation.Action) {
        switch action {
        case .delete:
            guard let userSession = ZMUserSession.shared() else { return }
            transitionToListAndEnqueue {
                self.conversation.deletePermanently(in: userSession) { (result) in
                    print("result: \(result)")
                }
            }
        case .archive(isArchived: let isArchived): self.transitionToListAndEnqueue {
            self.conversation.isArchived = !isArchived
            }
        case .markRead: self.enqueue {
            self.conversation.markAsRead()
            }
        case .markUnread: self.enqueue {
            self.conversation.markAsUnread()
            }
        case .configureNotifications: self.requestNotificationResult(for: self.conversation) { result in
            self.handleNotificationResult(result, for: self.conversation)
        }
        case .silence(isSilenced: let isSilenced): self.enqueue {
            self.conversation.mutedMessageTypes = isSilenced ? .none : .all 
            }
        case .leave: self.request(LeaveResult.self) { result in
            self.handleLeaveResult(result, for: self.conversation)
            }
        case .clearContent: self.requestClearContentResult(for: self.conversation) { result in
            self.handleClearContentResult(result, for: self.conversation)
            }
        case .cancelRequest:
            guard let user = self.conversation.connectedUser else { return }
            self.requestCancelConnectionRequestResult(for: user) { result in
                self.handleConnectionRequestResult(result, for: self.conversation)
            }
        case .block: self.requestBlockResult(for: self.conversation) { result in
            self.handleBlockResult(result, for: self.conversation)
            }
        case .remove: fatalError()
        }
    }
    
    private func alertAction(for action: ZMConversation.Action) -> UIAlertAction {
        return action.alertAction { [weak self] in
            guard let `self` = self else { return }
            self.handleAction(action)
        }
    }

    func present(_ controller: UIViewController) {
        present(controller,
                currentContext: currentContext,
                target: target)
    }
}
