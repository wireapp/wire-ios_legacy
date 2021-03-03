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

import Foundation
import UserNotifications
import UIKit

extension ConversationListViewController: PermissionDeniedViewControllerDelegate {
    public func continueWithoutPermission(_ viewController: PermissionDeniedViewController) {
        closePushPermissionDeniedDialog()
    }
}

extension ConversationListViewController {

    func closePushPermissionDialogIfNotNeeded() {
        UNUserNotificationCenter.current().checkPushesDisabled({ pushesDisabled in
            if !pushesDisabled,
                self.pushPermissionDeniedViewController != nil {
                DispatchQueue.main.async {
                    self.closePushPermissionDeniedDialog()
                }
            }
        })
    }

    func closePushPermissionDeniedDialog() {
        pushPermissionDeniedViewController?.willMove(toParent: nil)
        pushPermissionDeniedViewController?.view.removeFromSuperview()
        pushPermissionDeniedViewController?.removeFromParent()
        pushPermissionDeniedViewController = nil

        contentContainer.alpha = 1.0
    }

    func showPermissionDeniedViewController() {
        observeApplicationDidBecomeActive()

        let permissions = PermissionDeniedViewController.pushDeniedViewController()

        permissions.delegate = self

        addToSelf(permissions)

        permissions.view.translatesAutoresizingMaskIntoConstraints = false
        permissions.view.fitInSuperview()
        pushPermissionDeniedViewController = permissions

        concealContentContainer()
    }

    @objc func applicationDidBecomeActive(_ notif: Notification) {
        closePushPermissionDialogIfNotNeeded()
    }

    private func observeApplicationDidBecomeActive() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

    }
}
