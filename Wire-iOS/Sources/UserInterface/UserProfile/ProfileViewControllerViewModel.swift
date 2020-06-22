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
import WireDataModel
import WireSystem
import WireSyncEngine

private let zmLog = ZMSLog(tag: "ProfileViewControllerViewModel")

enum ProfileViewControllerContext {
    case search
    case groupConversation
    case oneToOneConversation
    case deviceList
    /// when opening from a URL scheme, not linked to a specific conversation
    case profileViewer
}

final class ProfileViewControllerViewModel: NSObject {
    let bareUser: UserType
    let conversation: ZMConversation?
    let viewer: UserType
    let context: ProfileViewControllerContext
    
    weak var delegate: ProfileViewControllerDelegate? {
        didSet {
            backButtonTitleDelegate = delegate as? BackButtonTitleDelegate
        }
    }

    
    weak var backButtonTitleDelegate: BackButtonTitleDelegate?
    
    private var observerToken: Any?
    weak var viewModelDelegate: ProfileViewControllerViewModelDelegate?

    init(bareUser: UserType,
         conversation: ZMConversation?,
         viewer: UserType,
         context: ProfileViewControllerContext) {
        self.bareUser = bareUser
        self.conversation = conversation
        self.viewer = viewer
        self.context = context

        super.init()
        
        if let fullUser = fullUser,
           let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: fullUser, in: userSession)
        }
    }
    
    var fullUser: ZMUser? {
        return (bareUser as? ZMUser) ?? (bareUser as? ZMSearchUser)?.user
    }

    var hasLegalHoldItem: Bool {
        return bareUser.isUnderLegalHold || conversation?.isUnderLegalHold == true
    }
    
    var shouldShowVerifiedShield: Bool {
        return bareUser.isVerified && context != .deviceList
    }
    
    var hasUserClientListTab: Bool {
        return nil != self.fullUser &&
            context != .search &&
            context != .profileViewer
    }
    
    var fullUserSet: UserSet {
        if let fullUser = fullUser {
            return UserSet(arrayLiteral: fullUser)
        } else {
            return UserSet()

        }
    }
    
    var incomingRequestFooterHidden: Bool {
        return !bareUser.isPendingApprovalBySelfUser
    }
    
    var blockTitle: String? {
        return BlockResult.title(for: bareUser)
    }
    
    var allBlockResult: [BlockResult] {
        return BlockResult.all(isBlocked: bareUser.isBlocked)
    }
    
    func cancelConnectionRequest(completion: @escaping Completion) {
        let user = fullUser
        ZMUserSession.shared()?.enqueue({
            user?.cancelConnectionRequest()
            completion()
        })
    }
    
    func toggleBlocked() {
        fullUser?.toggleBlocked()
    }
    
    func openOneToOneConversation() {
        guard let fullUser = fullUser else {
            zmLog.error("No user to open conversation with")
            return
        }
        var conversation: ZMConversation? = nil
        
        ZMUserSession.shared()?.enqueue({
            conversation = fullUser.oneToOneConversation
        }, completionHandler: {
            guard let conversation = conversation else { return }
            
            self.delegate?.profileViewController(self.viewModelDelegate as? ProfileViewController,
                                                 wantsToNavigateTo: conversation)
        })
    }
    
    // MARK: - Action Handlers
    
    func archiveConversation() {
        transitionToListAndEnqueue {
            self.conversation?.isArchived.toggle()
        }
    }
    
    func handleBlockAndUnblock() {
        switch context {
        case .search:
            /// stay on this VC and let user to decise what to do next
            enqueueChanges(toggleBlocked)
        default:
            transitionToListAndEnqueue { self.toggleBlocked() }
        }
    }

    // MARK: - Notifications
    
    func updateMute(enableNotifications: Bool) {
        ZMUserSession.shared()?.enqueue {
            self.conversation?.mutedMessageTypes = enableNotifications ? .none : .all
            // update the footer view to display the correct mute/unmute button
            self.viewModelDelegate?.updateFooterViews()
        }
    }
    
    func handleNotificationResult(_ result: NotificationResult) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            ZMUserSession.shared()?.perform {
                self.conversation?.mutedMessageTypes = mutedMessageTypes
            }
        }
    }

    // MARK: Delete Contents

    func handleDeleteResult(_ result: ClearContentResult) {
        guard case .delete(leave: let leave) = result else { return }
        transitionToListAndEnqueue {
            self.conversation?.clearMessageHistory()
            if leave {
                self.conversation?.removeOrShowError(participant: SelfUser.current)
            }
        }
    }


    // MARK: - Helpers
    
    func transitionToListAndEnqueue(leftViewControllerRevealed: Bool = true, _ block: @escaping () -> Void) {
        ZClientViewController.shared?.transitionToList(animated: true,
                                                       leftViewControllerRevealed: leftViewControllerRevealed) {
                                                        self.enqueueChanges(block)
        }
    }
    
    func enqueueChanges(_ block: @escaping () -> Void) {
        ZMUserSession.shared()?.enqueue(block)
    }

    // MARK: - Factories
    
    func makeUserNameDetailViewModel() -> UserNameDetailViewModel {
        return UserNameDetailViewModel(user: bareUser, fallbackName: bareUser.name ?? "", addressBookName: fullUser?.addressBookEntry?.cachedName)
    }
    
    var profileActionsFactory: ProfileActionsFactory {
        return ProfileActionsFactory(user: bareUser, viewer: viewer, conversation: conversation, context: context)
    }
    
    // MARK: Connect
    
    func sendConnectionRequest() {
        let connect: (String) -> Void = {
            if let user = self.fullUser {
                user.connect(message: $0)
            } else if let searchUser = self.bareUser as? ZMSearchUser {
                searchUser.connect(message: $0)
            }
        }
        
        ZMUserSession.shared()?.enqueue {
            let messageText = "missive.connection_request.default_message".localized(args: self.bareUser.name ?? "", self.viewer.name ?? "")
            connect(messageText)
            // update the footer view to display the cancel request button
            self.viewModelDelegate?.updateFooterViews()
        }
    }
    
    func acceptConnectionRequest() {
        guard let user = self.fullUser else { return }
        ZMUserSession.shared()?.enqueue {
            user.accept()
            user.refreshData()
            self.viewModelDelegate?.updateFooterViews()
        }
    }
    
    func ignoreConnectionRequest() {
        guard let user = self.fullUser else { return }
        ZMUserSession.shared()?.enqueue {
            user.ignore()
            self.viewModelDelegate?.returnToPreviousScreen()
        }
    }

}

extension ProfileViewControllerViewModel: ZMUserObserver {
    func userDidChange(_ note: UserChangeInfo) {
        if note.trustLevelChanged {
            viewModelDelegate?.updateShowVerifiedShield()
        }
        
        if note.legalHoldStatusChanged {
            viewModelDelegate?.setupNavigationItems()
        }

        if note.nameChanged {
            viewModelDelegate?.updateTitleView()
        }
        
        if note.user.isAccountDeleted {
            viewModelDelegate?.updateFooterViews()
        }
    }
}

extension ProfileViewControllerViewModel: BackButtonTitleDelegate {
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String? {
        return bareUser.name?.uppercasedWithCurrentLocale
    }
}

protocol ProfileViewControllerViewModelDelegate: class {
    func updateShowVerifiedShield()
    func setupNavigationItems()
    func updateFooterViews()
    func updateTitleView()
    func returnToPreviousScreen()
}
