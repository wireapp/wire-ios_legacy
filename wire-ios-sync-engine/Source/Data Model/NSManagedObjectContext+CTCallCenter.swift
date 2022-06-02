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

import Foundation
import CoreTelephony

public extension NSManagedObjectContext {

    private static let WireCallCenterKey = "WireCallCenterKey"

    @objc
    var zm_callCenter: WireCallCenterV3? {

        get {
            precondition(zm_isUserInterfaceContext, "callCenter can only be accessed on the ui context")
            return userInfo[NSManagedObjectContext.WireCallCenterKey] as? WireCallCenterV3
        }

        set {
            precondition(zm_isUserInterfaceContext, "callCenter can only be accessed on the ui context")
            userInfo[NSManagedObjectContext.WireCallCenterKey] = newValue
        }

    }

    private static let ConstantBitRateAudioKey = "ConstantBitRateAudioKey"

    @objc
    var zm_useConstantBitRateAudio: Bool {

        get {
            precondition(zm_isUserInterfaceContext, "zm_useConstantBitRateAudio can only be accessed on the ui context")
            return userInfo[NSManagedObjectContext.ConstantBitRateAudioKey] as? Bool ?? false
        }

        set {
            precondition(zm_isUserInterfaceContext, "zm_useConstantBitRateAudio can only be accessed on the ui context")
            userInfo[NSManagedObjectContext.ConstantBitRateAudioKey] = newValue
        }

    }
}
