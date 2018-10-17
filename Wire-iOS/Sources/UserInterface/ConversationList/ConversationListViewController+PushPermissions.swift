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

extension ConversationListViewController: PermissionDeniedViewControllerDelegate {}

extension Settings {
    var pushAlertHappenedMoreThan1DayBefore: Bool {
        guard let date = self.lastPushAlertDate else {
            return true
        }
        return abs(Float(date.timeIntervalSinceNow)) > 60 * 60 * 24
    }
}

extension ConversationListViewController {

    @objc func closePushPermissionDialogIfNotNeeded() {
        UNUserNotificationCenter.current().checkPushesDisabled({ pushesDisabled in
            if !pushesDisabled,
                let _ = self.pushPermissionDeniedViewController {
                DispatchQueue.main.async {
                    self.closePushPermissionDeniedDialog()
                }
            }
        })
    }

    @objc func closePushPermissionDeniedDialog() {
        pushPermissionDeniedViewController?.willMove(toParent: nil)
        pushPermissionDeniedViewController?.view.removeFromSuperview()
        pushPermissionDeniedViewController?.removeFromParent()
        pushPermissionDeniedViewController = nil

        contentContainer.alpha = 1.0
    }

    @objc func showPushPermissionDeniedDialogIfNeeded() {
        // We only want to present the notification takeover when the user already has a handle
        // and is not coming from the registration flow (where we alreday ask for permissions).
        if !isComingFromRegistration || nil == ZMUser.selfUser().handle {
            return
        }

        if AutomationHelper.sharedHelper.skipFirstLoginAlerts || usernameTakeoverViewController != nil {
            return
        }

        let pushAlertHappenedMoreThan1DayBefore: Bool = Settings.shared().pushAlertHappenedMoreThan1DayBefore

        if !pushAlertHappenedMoreThan1DayBefore {
            return
        }

        UNUserNotificationCenter.current().checkPushesDisabled({ pushesDisabled in
            DispatchQueue.main.async {
                if pushesDisabled {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
                    Settings.shared().lastPushAlertDate = Date()
                    if let permissions = PermissionDeniedViewController.push() {
                        permissions.delegate = self

                        self.addChild(permissions)
                        self.view.addSubview(permissions.view)
                        permissions.didMove(toParent: self)

                        permissions.view.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
                        self.pushPermissionDeniedViewController = permissions
                    }

                    self.contentContainer.alpha = 0.0
                }
            }
        })
    }

    @objc func applicationDidBecomeActive(_ notif: Notification) {
        closePushPermissionDialogIfNotNeeded()
    }
}
