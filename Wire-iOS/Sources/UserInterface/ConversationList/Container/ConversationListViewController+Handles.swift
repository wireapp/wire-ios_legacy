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

extension ConversationListViewController {

    func removeUsernameTakeover() {
        guard let takeover = usernameTakeoverViewController else { return }
        takeover.willMove(toParent: nil)
        takeover.view.removeFromSuperview()
        takeover.removeFromParent()
        contentContainer.alpha = 1
        usernameTakeoverViewController = nil

        if parent?.presentedViewController is SettingsStyleNavigationController {
            parent?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    func openChangeHandleViewController(with handle: String) {
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

    func showUsernameTakeover(suggestedHandle: String, name: String) {
        guard nil == usernameTakeoverViewController else { return }

        let usernameTakeoverViewController = UserNameTakeOverViewController(suggestedHandle: suggestedHandle, name: name)
        usernameTakeoverViewController.delegate = viewModel

        addToSelf(usernameTakeoverViewController)
        concealContentContainer()

        if let takeover = usernameTakeoverViewController.view {
            takeover.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
              takeover.topAnchor.constraint(equalTo: view.topAnchor),
              takeover.bottomAnchor.constraint(equalTo: view.bottomAnchor),
              takeover.leftAnchor.constraint(equalTo: view.leftAnchor),
              takeover.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        }

        self.usernameTakeoverViewController = usernameTakeoverViewController
    }

    func concealContentContainer() {
        contentContainer.alpha = 0
    }

    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler) {
        UIAlertController.showNewsletterSubscriptionDialogIfNeeded(presentViewController: self, completionHandler: completionHandler)
    }
}
