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

@objc
public protocol CallNotificationStyleProvider: AnyObject {

    var callNotificationStyle: CallNotificationStyle { get }

}

@objc extension ZMUserSession: CallNotificationStyleProvider {

    public var callCenter: WireCallCenterV3? {
        return managedObjectContext.zm_callCenter
    }

    public var callNotificationStyle: CallNotificationStyle {
        return sessionManager?.callNotificationStyle ?? .pushNotifications
    }

    public var isCallOngoing: Bool {
        guard let callCenter = callCenter else { return false }

        return !callCenter.activeCallConversations(in: self).isEmpty
    }

    internal var callKitManager: CallKitManager? {
        return sessionManager?.callKitManager
    }

    var useConstantBitRateAudio: Bool {
        get {
            return managedObjectContext.zm_useConstantBitRateAudio
        }
        set {
            managedObjectContext.zm_useConstantBitRateAudio = newValue
            callCenter?.useConstantBitRateAudio = newValue
        }

    }

    var usePackagingFeatureConfig: Bool {
        get {
            return managedObjectContext.zm_usePackagingFeatureConfig
        }
        set {
            managedObjectContext.zm_usePackagingFeatureConfig = newValue
            callCenter?.usePackagingFeatureConfig = newValue
        }

    }
}
