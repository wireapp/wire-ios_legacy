//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireSyncEngine

protocol ScreenCurtainDelegate: class {

    /// Whether the screen curtain should be shown when the app
    /// resigns active.

    var shouldShowScreenCurtain: Bool { get }

}

extension ZMUserSession: ScreenCurtainDelegate {

    var shouldShowScreenCurtain: Bool {
        return appLockController.isActive || encryptMessagesAtRest
    }

}
