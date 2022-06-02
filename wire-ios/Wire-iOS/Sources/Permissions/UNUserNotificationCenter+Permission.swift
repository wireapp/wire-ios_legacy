////
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

extension UNUserNotificationCenter {

    /**
     * Checks asynchronously whether push notifications are disabled, that is,
     * when either the app is not registered for remote notifications or the
     * user did not authorize to receive remote/local notifications.
     *
     * - parameter handler: A block that accepts one boolean argument, whose
     * value is true iff the pushes are disabled.
     */
    func checkPushesDisabled(_ handler: @escaping (Bool) -> Void) {
        getNotificationSettings { settings in
            let pushesDisabled = settings.authorizationStatus == .denied
            handler(pushesDisabled)
        }
    }
}
