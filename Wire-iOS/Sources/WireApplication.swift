//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@objcMembers public class WireApplication: UIApplication {
    
    var shouldRegisterUserNotificationSettings: Bool {
        return !(AutomationHelper.sharedHelper.skipFirstLoginAlerts || AutomationHelper.sharedHelper.disablePushNotificationAlert)
    }
    
    override public func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        DebugAlert.showSendLogsMessage(
            message: "You have performed a shake motion, please confirm sending debug logs."
        )
    }
}
