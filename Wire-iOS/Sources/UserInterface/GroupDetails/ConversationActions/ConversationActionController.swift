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

@objc final class ConversationActionController: NSObject {
    
    private let conversation: ZMConversation
    unowned let target: UIViewController
    
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
        controller.view.tintColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .light)
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

extension ZMConversation {
    enum Action {
        case delete
        case leave
        case silence(isSilenced: Bool)
        case archive(isArchived: Bool)
        case cancelRequest
        case block(isBlocked: Bool)
    }
    
    var actions: [Action] {
        switch conversationType {
        case .connection: return availableOneToOneActions()
        case .oneOnOne: return availableOneToOneActions()
        default: return availableGroupActions()
        }
    }
    
    private func availableOneToOneActions() -> [Action] {
        precondition(conversationType == .oneOnOne)
        var actions = [Action]()
        if nil == team, let connectedUser = connectedUser {
            actions.append(.block(isBlocked: connectedUser.isBlocked))
        }
        actions.append(contentsOf: availableStandardActions())
        actions.append(.delete)
        return actions
    }
    
    private func availablePendingActions() -> [Action] {
        precondition(conversationType == .connection)
        return [.archive(isArchived: isArchived), .cancelRequest]
    }
    
    private func availableGroupActions() -> [Action] {
        var actions = availableStandardActions() + [.delete]
        if activeParticipants.contains(ZMUser.selfUser()) {
            actions.append(.leave)
        }
        return actions
    }
    
    private func availableStandardActions() -> [Action] {
        var actions = [Action]()
        if !isReadOnly {
            actions.append(.silence(isSilenced: isSilenced))
        }
        actions.append(.archive(isArchived: isArchived))
        return actions
    }
}

extension ZMConversation.Action {
    
    fileprivate var style: UIAlertActionStyle {
        switch self {
        case .delete, .leave: return .destructive
        default: return .default
        }
    }
    
    fileprivate var title: String {
        return localizationKey.localized
    }
    
    private var localizationKey: String {
        switch self {
        case .delete: return "meta.menu.delete"
        case .leave: return "meta.menu.leave"
        case .silence(isSilenced: let muted): return "meta.menu.silence.\(muted ? "unmute" : "mute")"
        case .archive(isArchived: let archived): return "meta.menu.\(archived ? "unarchive" : "archive")"
        case .cancelRequest: return "meta.menu.cancel_connection_request"
        case .block(isBlocked: let blocked): return blocked ? "profile.unblock_button_title" : "profile.block_dialog.button_block"
        }
    }
    
    func alertAction(handler: @escaping () -> Void) -> UIAlertAction {
        return .init(title: title, style: style) { _ in handler() }
    }
}
