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


import UIKit
import Cartography

/// Debug flag to ensure the takeover screen is shown even though
/// the selfUser already has a handle assigned.
private let debugOverrideShowTakeover = false

extension ConversationListViewController {

    func showUsernameTakeover(with handle: String) {
        guard let name = ZMUser.selfUser().name, nil == ZMUser.selfUser().handle || debugOverrideShowTakeover else { return }
        guard nil == usernameTakeoverViewController else { return }
        usernameTakeoverViewController = UserNameTakeOverViewController(suggestedHandle: handle, name: name)
        usernameTakeoverViewController.delegate = self

        addChild(usernameTakeoverViewController)
        view.addSubview(usernameTakeoverViewController.view)
        usernameTakeoverViewController.didMove(toParent: self)
        contentContainer.alpha = 0

        constrain(view, usernameTakeoverViewController.view) { view, takeover in
            takeover.edges == view.edges
        }

        guard traitCollection.userInterfaceIdiom == .pad else { return }
        ZClientViewController.shared()?.loadPlaceholderConversationController(animated: false)
    }

    func removeUsernameTakeover() {
        guard let takeover = usernameTakeoverViewController else { return }
        takeover.willMove(toParent: nil)
        takeover.view.removeFromSuperview()
        takeover.removeFromParent()
        contentContainer.alpha = 1
        usernameTakeoverViewController = nil
        removeUserProfileObserver()

        if parent?.presentedViewController is SettingsStyleNavigationController {
            parent?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    fileprivate func openChangeHandleViewController(with handle: String) {
        // We need to ensure we are currently showing the takeover as this
        // callback will also get invoked when changing the handle from the settings view controller.
        guard !(parent?.presentedViewController is SettingsStyleNavigationController) else { return }
        guard nil != usernameTakeoverViewController else { return }

        let handleController = ChangeHandleViewController(suggestedHandle: handle)
        handleController.popOnSuccess = false
        handleController.view.backgroundColor = .black
        let navigationController = SettingsStyleNavigationController(rootViewController: handleController)
        navigationController.modalPresentationStyle = .formSheet

        parent?.present(navigationController, animated: true, completion: nil)
    }

    fileprivate func setSuggested(handle: String) {
        userProfile?.requestSettingHandle(handle: handle)
    }

}


extension ConversationListViewController: UserNameTakeOverViewControllerDelegate {

    func takeOverViewController(_ viewController: UserNameTakeOverViewController, didPerformAction action: UserNameTakeOverViewControllerAction) {

        perform(action)

        // show data usage dialog after user name take over screen
        showDataUsagePermissionDialogIfNeeded()
    }

    private func perform(_ action: UserNameTakeOverViewControllerAction) {
        switch action {
        case .chooseOwn(let suggested): openChangeHandleViewController(with: suggested)
        case .keepSuggestion(let suggested): setSuggested(handle: suggested)
        case .learnMore: URL.wr_usernameLearnMore.openInApp(above: self)
        }
    }
}


extension ConversationListViewController: UserProfileUpdateObserver {

    public func didFailToSetHandle() {
        openChangeHandleViewController(with: "")
    }

    public func didFailToSetHandleBecauseExisting() {
        openChangeHandleViewController(with: "")
    }

    public func didSetHandle() {
        removeUsernameTakeover()
    }

    public func didFindHandleSuggestion(handle: String) {
        showUsernameTakeover(with: handle)
        if let userSession = ZMUserSession.shared(), let selfUser = ZMUser.selfUser() {
            selfUser.fetchMarketingConsent(in: userSession, completion: { result in
                switch result {
                case .failure:
                    UIAlertController.showNewsletterSubscriptionDialogIfNeeded(presentViewController: self) { marketingConsent in
                        selfUser.setMarketingConsent(to: marketingConsent, in: userSession, completion: { _ in })
                    }

                case .success:
                    // The user already gave a marketing consent, no need to ask for it again.
                    return
                }
            })
        }

        // When the user have to set user name, i.e. the user is a invited team user, show data usage permission dialog
        self.isComingFromSetUsername = true
    }

}


extension ConversationListViewController: ZMUserObserver {

    public func userDidChange(_ note: UserChangeInfo) {
        if ZMUser.selfUser().handle != nil && note.handleChanged {
            removeUsernameTakeover()
        } else if note.teamsChanged {
            updateNoConversationVisibility()
        }
    }
}
