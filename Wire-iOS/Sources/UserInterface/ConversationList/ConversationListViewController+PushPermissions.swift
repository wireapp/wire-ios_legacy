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

extension ConversationListViewController: PermissionDeniedViewControllerDelegate {
    public func continueWithoutPermission(_ viewController: PermissionDeniedViewController!) {
        closePushPermissionDeniedDialog()
    }
}

extension Settings {
    var pushAlertHappenedMoreThan1DayBefore: Bool {
        guard let date = self.lastPushAlertDate else {
            return true
        }

        return date.timeIntervalSinceNow < -86400
    }
}

extension ConversationListViewController {

    func closePushPermissionDialogIfNotNeeded() {
        UNUserNotificationCenter.current().checkPushesDisabled({ pushesDisabled in
            if !pushesDisabled,
                let _ = self.pushPermissionDeniedViewController {
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

    private var isComingFromRegistration: Bool {
        return ZClientViewController.shared()?.isComingFromRegistration ?? false
    }

    func showPushPermissionDeniedDialogIfNeeded() {
        // We only want to present the notification takeover when the user already has a handle
        // and is not coming from the registration flow (where we alreday ask for permissions).
        if isComingFromRegistration || nil == ZMUser.selfUser().handle {
            return
        }

        if AutomationHelper.sharedHelper.skipFirstLoginAlerts || usernameTakeoverViewController != nil {
            return
        }

        let pushAlertHappenedMoreThan1DayBefore: Bool = Settings.shared().pushAlertHappenedMoreThan1DayBefore

        if !pushAlertHappenedMoreThan1DayBefore {
            return
        }

        UNUserNotificationCenter.current().checkPushesDisabled({ [weak self] pushesDisabled in
            DispatchQueue.main.async {
                if pushesDisabled,
                    let weakSelf = self {
                    NotificationCenter.default.addObserver(weakSelf, selector: #selector(weakSelf.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
                    Settings.shared().lastPushAlertDate = Date()

                    weakSelf.showPermissionDeniedViewController()

                    weakSelf.contentContainer.alpha = 0.0
                }
            }
        })
    }

    func showPermissionDeniedViewController() {
        if let permissions = PermissionDeniedViewController.push() {
            permissions.delegate = self

            addToSelf(permissions)

            permissions.view.translatesAutoresizingMaskIntoConstraints = false
            permissions.view.fitInSuperview()
            pushPermissionDeniedViewController = permissions
        }
    }

    @objc func applicationDidBecomeActive(_ notif: Notification) {
        closePushPermissionDialogIfNotNeeded()
    }
}
