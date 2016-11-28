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


extension ConversationListViewController {

    func showUsernameTakeover(with handle: String) {
        guard let selfUser = ZMUser.selfUser(), nil == selfUser.handle, nil == usernameTakeoverViewController else { return }
        usernameTakeoverViewController = UserNameTakeOverViewController(suggestedHandle: handle, displayName: selfUser.displayName)
        usernameTakeoverViewController.delegate = self

        addChildViewController(usernameTakeoverViewController)
        view.addSubview(usernameTakeoverViewController.view)
        usernameTakeoverViewController.didMove(toParentViewController: self)
        contentContainer.alpha = 0

        constrain(view, usernameTakeoverViewController.view) { view, takeover in
            takeover.edges == view.edges
        }

        ZClientViewController.shared().loadPlaceholderConversationController(animated: false)
    }

    func removeUsernameTakeover() {
        guard let takeover = usernameTakeoverViewController else { return }
        takeover.willMove(toParentViewController: nil)
        takeover.view.removeFromSuperview()
        takeover.removeFromParentViewController()
        contentContainer.alpha = 1
        usernameTakeoverViewController = nil

        if parent?.presentedViewController is SettingsStyleNavigationController {
            parent?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    fileprivate func openChangeHandleViewController(with handle: String) {
        let handleController = ChangeHandleViewController(suggestedHandle: handle)
        handleController.popOnSuccess = false
        handleController.view.backgroundColor = .black
        let navigationController = SettingsStyleNavigationController(rootViewController: handleController)
        navigationController.modalPresentationStyle = .formSheet

        parent?.present(navigationController, animated: true, completion: nil)
    }

    fileprivate func setSuggested(handle: String) {
        userProfile.requestSettingHandle(handle: handle)
    }

}


extension ConversationListViewController: UserNameTakeOverViewControllerDelegate {

    func takeOverViewController(_ viewController: UserNameTakeOverViewController, didPerformAction action: UserNameTakeOverViewControllerAction) {
        switch action {
        case .chooseOwn(let suggested): openChangeHandleViewController(with: suggested)
        case .keepSuggestion(let suggested): setSuggested(handle: suggested)
        case .learnMore: URL(string: "https://www.wire.com")?.open() // TODO: Insert correct URL
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
    }

}

