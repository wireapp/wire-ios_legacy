
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

extension ConversationListViewController.ViewModel: UserProfileUpdateObserver {

    public func didFailToSetHandle() {
        viewController.openChangeHandleViewController(with: "")
    }

    public func didFailToSetHandleBecauseExisting() {
        viewController.openChangeHandleViewController(with: "")
    }

    public func didSetHandle() {
        removeUsernameTakeover()
    }

    public func didFindHandleSuggestion(handle: String) {
        showUsernameTakeover(with: handle)
        if let userSession = ZMUserSession.shared(), let selfUser = ZMUser.selfUser() {
            selfUser.fetchMarketingConsent(in: userSession, completion: { result in
                switch result {
                case .failure:///TODO: move to VC
                    UIAlertController.showNewsletterSubscriptionDialogIfNeeded(presentViewController: self.viewController) { marketingConsent in
                        selfUser.setMarketingConsent(to: marketingConsent, in: userSession, completion: { _ in })
                    }

                case .success:
                    // The user already gave a marketing consent, no need to ask for it again.
                    return
                }
            })
        }
    }

}

extension ConversationListViewController.ViewModel: ZMUserObserver {

    public func userDidChange(_ note: UserChangeInfo) {
        if ZMUser.selfUser().handle != nil && note.handleChanged {
            removeUsernameTakeover()
        } else if note.teamsChanged {
            viewController.updateNoConversationVisibility()
        }
    }
}

typealias ConversationCreatedBlock = (ZMConversation?) -> Void

extension ConversationListViewController.ViewModel {
    func createConversation(withUsers users: Set<ZMUser>?, name: String?, allowGuests: Bool, enableReceipts: Bool) {
        guard let users = users,
            let userSession = ZMUserSession.shared() else { return }

        var conversation: ZMConversation! = nil

        userSession.enqueueChanges({
            conversation = ZMConversation.insertGroupConversation(intoUserSession: userSession, withParticipants: Array(users), name: name, in: ZMUser.selfUser().team, allowGuests: allowGuests, readReceipts: enableReceipts)
        }, completionHandler:{
            delay(0.3) {                ZClientViewController.shared()?.select(conversation, focusOnView: true, animated: true)
            }
        })
    }

    func withConversationForUsers(_ users: Set<ZMUser>?, callback onConversationCreated: @escaping ConversationCreatedBlock) {

        guard let users = users,
            let userSession = ZMUserSession.shared() else { return }

        viewController.dismissPeoplePicker(with: {
            if users.count == 1,
                let user = users.first {
                var oneToOneConversation: ZMConversation? = nil
                userSession.enqueueChanges({
                    oneToOneConversation = user.oneToOneConversation
                }, completionHandler: {
                    delay(0.3) {
                        onConversationCreated(oneToOneConversation)
                    }
                })
            } else if users.count > 1 {
                var conversation: ZMConversation? = nil

                userSession.enqueueChanges({
                    let team = ZMUser.selfUser().team

                    conversation = ZMConversation.insertGroupConversation(intoUserSession: userSession, withParticipants: Array(users), in: team)
                }, completionHandler: {
                    delay(0.3) {
                        onConversationCreated(conversation)
                    }
                })
            }
        })
    }
}

/// Debug flag to ensure the takeover screen is shown even though
/// the selfUser already has a handle assigned.
private let debugOverrideShowTakeover = false

extension ConversationListViewController.ViewModel {
    func removeUsernameTakeover() {
        viewController.removeUsernameTakeover()
        removeUserProfileObserver()
    }

    func showUsernameTakeover(with handle: String) {
        guard let name = ZMUser.selfUser().name, nil == ZMUser.selfUser().handle || debugOverrideShowTakeover else { return }
        viewController.showUsernameTakeover(suggestedHandle: handle, name: name)
        ZClientViewController.shared()?.loadPlaceholderConversationController(animated: false)
    }

}

