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
    let user: UserType
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

    init(user: UserType,
         conversation: ZMConversation?,
         viewer: UserType,
         context: ProfileViewControllerContext) {
        self.user = user
        self.conversation = conversation
        self.viewer = viewer
        self.context = context

        super.init()

        if let user = user as? ZMUser,
           let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }
    }

    var hasLegalHoldItem: Bool {
        return user.isUnderLegalHold || conversation?.isUnderLegalHold == true
    }

    var shouldShowVerifiedShield: Bool {
        return user.isVerified && context != .deviceList
    }

    var hasUserClientListTab: Bool {
        return context != .search &&
            context != .profileViewer
    }

    var userSet: UserSet {
        return UserSet(arrayLiteral: user)
    }

    var incomingRequestFooterHidden: Bool {
        return !user.isPendingApprovalBySelfUser
    }

    var blockTitle: String? {
        return BlockResult.title(for: user)
    }

    var allBlockResult: [BlockResult] {
        return BlockResult.all(isBlocked: user.isBlocked)
    }

    func cancelConnectionRequest(completion: @escaping Completion) {
        ZMUserSession.shared()?.enqueue({
            self.user.cancelConnectionRequest()
            completion()
        })
    }

    func toggleBlocked() {
        user.toggleBlocked()
    }

    func openOneToOneConversation() {
        var conversation: ZMConversation?

        ZMUserSession.shared()?.enqueue({
            conversation = self.user.oneToOneConversation
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
        // TODO: add addressBookEntry to ZMUser
        return UserNameDetailViewModel(user: user, fallbackName: user.name ?? "", addressBookName: (user as? ZMUser)?.addressBookEntry?.cachedName)
    }

    var profileActionsFactory: ProfileActionsFactory {
        return ProfileActionsFactory(user: user, viewer: viewer, conversation: conversation, context: context)
    }

    // MARK: Connect

    func sendConnectionRequest() {
        if user.isFederated {
            var conversation: ZMConversation?
            guard let session = ZMUserSession.shared() else { return }
            session.enqueue({
                conversation = self.user.createFederatedOneToOne(in: session)
            }, completionHandler: {
                guard let conversation = conversation else { return }
                self.delegate?.profileViewController(self.viewModelDelegate as? ProfileViewController,
                                                     wantsToNavigateTo: conversation)
            })
        } else {
            ZMUserSession.shared()?.enqueue {
                let messageText = "missive.connection_request.default_message".localized(args: self.user.name ?? "", self.viewer.name ?? "")
                self.user.connect(message: messageText)
                // update the footer view to display the cancel request button
                self.viewModelDelegate?.updateFooterViews()
            }
        }
    }

    func acceptConnectionRequest() {
        ZMUserSession.shared()?.enqueue {
            self.user.accept()
            self.user.refreshData()
            self.viewModelDelegate?.updateFooterViews()
        }
    }

    func ignoreConnectionRequest() {
        ZMUserSession.shared()?.enqueue {
            self.user.ignore()
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
        return user.name?.uppercasedWithCurrentLocale
    }
}

protocol ProfileViewControllerViewModelDelegate: class {
    func updateShowVerifiedShield()
    func setupNavigationItems()
    func updateFooterViews()
    func updateTitleView()
    func returnToPreviousScreen()
}
