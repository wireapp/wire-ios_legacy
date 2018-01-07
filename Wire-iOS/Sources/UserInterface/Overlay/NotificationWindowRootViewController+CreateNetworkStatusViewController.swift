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
import Cartography

extension NotificationWindowRootViewController {

    func createNotificationWindowRootViewControllerConstraints() {
        constrain(self.view, networkStatusViewController!.view) { selfView, networkStatusView in
            networkStatusView.leading == selfView.leading + 16
            networkStatusView.trailing == selfView.trailing - 16
            networkStatusView.top == selfView.top + 28 ///TODO: iPhone X
            networkStatusView.bottom == selfView.bottom
        }
    }

}
