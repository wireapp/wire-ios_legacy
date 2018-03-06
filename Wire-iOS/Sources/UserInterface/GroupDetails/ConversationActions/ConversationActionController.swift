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

@objc protocol ConversationActionControllerRenameDelegate: class {
    func controllerWantsToRenameConversation(_ controller: ConversationActionController)
}

@objc final class ConversationActionController: NSObject {
    
    private let conversation: ZMConversation
    unowned let target: UIViewController
    weak var renameDelegate: ConversationActionControllerRenameDelegate? // Only relevant for group conversations and the rename action
    
    @objc init(conversation: ZMConversation, target: UIViewController) {
        // Does not support blocking yet (1-on-1)
        requireInternal(conversation.conversationType == .group, "currently only allowed for group conversations")
        self.conversation = conversation
        self.target = target
        super.init()
    }
    
    func presentMenu() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        conversation.actions.map(alertAction).forEach(controller.addAction)
        controller.addAction(.cancel())
        target.present(controller, animated: true)
    }
    
    private func dismiss(_ block: @escaping () -> Void) {
        target.dismiss(animated: true, completion: block)
    }
    
    private func dismissAndEnqueue(_ block: @escaping () -> Void) {
        target.dismiss(animated: true) {
            ZMUserSession.shared()?.enqueueChanges(block)
        }
    }
    
    func transitionToListAndEnqueue(_ block: @escaping () -> Void) {
        target.dismiss(animated: true) {
            ZClientViewController.shared()?.transitionToList(animated: true) {
                ZMUserSession.shared()?.enqueueChanges(block)
            }
        }
    }
    
    private func alertAction(for action: ZMConversation.Action) -> UIAlertAction {
        switch action {
        case .rename: return action.alertAction { [weak self] in
            guard let `self` = self else { return }
            self.renameDelegate?.controllerWantsToRenameConversation(self)
        }
        case .archive(isArchived: let isArchived): return action.alertAction { [weak self] in
            guard let `self` = self else { return }
            self.transitionToListAndEnqueue {
                self.conversation.isArchived = !isArchived
                Analytics.shared().tagArchivedConversation(!isArchived)
            }
        }
        case .silence(isSilenced: let isSilenced): return action.alertAction { [weak self] in
            guard let `self` = self else { return }
            self.dismissAndEnqueue {
                self.conversation.isSilenced = !isSilenced
            }
        }
        case .leave: return action.alertAction { [weak self] in
            guard let `self` = self else { return }
            self.request(LeaveResult.self) { result in
                self.handleLeaveResult(result, for: self.conversation)
            }
        }
        case .delete: return action.alertAction { [weak self] in
            guard let `self` = self else { return }
            self.request(DeleteResult.self) { result in
                self.handleDeleteResult(result, for: self.conversation)
            }
        }
        default: fatalError() // Does not support blocking yet (1-on-1)
        }
    }
    
}
