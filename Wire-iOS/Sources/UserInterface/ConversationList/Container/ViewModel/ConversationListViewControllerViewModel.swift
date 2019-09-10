
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

typealias Completion = ()->()
typealias CompletionHandler = (Bool) -> Void

protocol ConversationListContainerViewModelDelegate: class {
    init(selfUser: SelfUserType, viewModel: ConversationListViewController.ViewModel)

    func updateBottomBarSeparatorVisibility(with controller: ConversationListContentController)
    func dismissPeoplePicker(with block: @escaping Completion)
    func scrollViewDidScroll(scrollView: UIScrollView!)

    func setState(_ state: ConversationListState,
    animated: Bool,
    completion: Completion?)

    func showNoContactLabel()
    func hideNoContactLabel(animated: Bool)

    func openChangeHandleViewController(with handle: String)
    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping CompletionHandler)
    func updateArchiveButtonVisibilityIfNeeded(showArchived: Bool)

    func removeUsernameTakeover()
    func showUsernameTakeover(suggestedHandle: String, name: String)

    func observeApplicationDidBecomeActive()
    func concealContentContainer()

    func showPermissionDeniedViewController()

    @discardableResult
    func selectOnListContentController(_ conversation: ZMConversation!, scrollTo message: ZMConversationMessage?, focusOnView focus: Bool, animated: Bool, completion: (() -> Void)?) -> Bool

    var hasUsernameTakeoverViewController: Bool { get }
}

extension ConversationListViewController: ConversationListContainerViewModelDelegate {}

extension ConversationListViewController {
    final class ViewModel: NSObject {
        weak var viewController: ConversationListContainerViewModelDelegate! {
            didSet {
                guard let _ = viewController else { return }

                updateNoConversationVisibility()
                updateArchiveButtonVisibility()
                showPushPermissionDeniedDialogIfNeeded()
            }
        }

        let account: Account
        var selectedConversation: ZMConversation?

        weak var userProfile: UserProfile? = ZMUserSession.shared()?.userProfile

        var userProfileObserverToken: Any?
        fileprivate var initialSyncObserverToken: Any?
        fileprivate var userObserverToken: Any?
        /// observer tokens which are assigned when viewDidLoad
        var allConversationsObserverToken: Any?
        var connectionRequestsObserverToken: Any?

        var actionsController: ConversationActionController?

        init(account: Account) {
            self.account = account
        }
    }
}

extension ConversationListViewController.ViewModel {
    func setupObservers() {
        if let userSession = ZMUserSession.shared(),
            let selfUser = ZMUser.selfUser() {
            userObserverToken = UserChangeInfo.add(observer: self, for: selfUser, userSession: userSession) as Any

            initialSyncObserverToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }

        updateObserverTokensForActiveTeam()
    }

    func savePendingLastRead() {
        ZMUserSession.shared()?.enqueueChanges({
            self.selectedConversation?.savePendingLastRead()
        })
    }


    /// Select a conversation and move the focus to the conversation view.
    ///
    /// - Parameters:
    ///   - conversation: the conversation to select
    ///   - message: scroll to  this message
    ///   - focus: focus on the view or not
    ///   - animated: perform animation or not
    ///   - completion: the completion block
    func select(_ conversation: ZMConversation,
                scrollTo message: ZMConversationMessage? = nil,
                focusOnView focus: Bool = false,
                animated: Bool = false,
                completion: (() -> ())? = nil) {
        selectedConversation = conversation

        viewController.dismissPeoplePicker(with: { [weak self] in
            self?.viewController.selectOnListContentController(self?.selectedConversation, scrollTo: message, focusOnView: focus, animated: animated, completion: completion)
        })
    }

    func removeUserProfileObserver() {
        userProfileObserverToken = nil
    }

    func requestSuggestedHandlesIfNeeded() {
        guard let session = ZMUserSession.shared(),
            let userProfile = userProfile else { return }

        if nil == ZMUser.selfUser()?.handle,
            session.hasCompletedInitialSync == true,
            session.isPendingHotFixChanges == false {

            userProfileObserverToken = userProfile.add(observer: self)
            userProfile.suggestHandles()
        }
    }

    func setSuggested(handle: String) {
        userProfile?.requestSettingHandle(handle: handle)
    }

    private var isComingFromRegistration: Bool {
        return ZClientViewController.shared()?.isComingFromRegistration ?? false
    }


    /// show PushPermissionDeniedDialog when necessary
    ///
    /// - Returns: true if PushPermissionDeniedDialog is shown

    @discardableResult
    func showPushPermissionDeniedDialogIfNeeded() -> Bool {
        // We only want to present the notification takeover when the user already has a handle
        // and is not coming from the registration flow (where we alreday ask for permissions).
        guard ZMUser.selfUser().handle != nil else { return false }
        guard !isComingFromRegistration else { return false }

        guard !AutomationHelper.sharedHelper.skipFirstLoginAlerts else { return false }
        guard !viewController.hasUsernameTakeoverViewController else { return false }

        guard Settings.shared().pushAlertHappenedMoreThan1DayBefore else { return false }

        UNUserNotificationCenter.current().checkPushesDisabled({ [weak self] pushesDisabled in
            DispatchQueue.main.async {
                if pushesDisabled,
                    let weakSelf = self {
                    weakSelf.viewController.observeApplicationDidBecomeActive()

                    Settings.shared().lastPushAlertDate = Date()

                    weakSelf.viewController.showPermissionDeniedViewController()

                    weakSelf.viewController.concealContentContainer()
                }
            }
        })

        return true
    }

}

extension ConversationListViewController.ViewModel: ZMInitialSyncCompletionObserver {
    func initialSyncCompleted() {
        requestSuggestedHandlesIfNeeded()
    }
}

extension Settings {
    var pushAlertHappenedMoreThan1DayBefore: Bool {
        guard let date = lastPushAlertDate else {
            return true
        }

        return date.timeIntervalSinceNow < -86400
    }
}
