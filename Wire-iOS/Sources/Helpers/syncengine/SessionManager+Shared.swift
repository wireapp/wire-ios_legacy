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
import WireSyncEngine
import AVFoundation

extension SessionManager {
    @objc static var shared : SessionManager? {
        return AppDelegate.shared().sessionManager
    }
    
    @objc public func updateCallNotificationStyleFromSettings() {
        let isCallKitEnabled = !Settings.shared().disableCallKit
        let hasAudioPermissions = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == AVAuthorizationStatus.authorized
        let isCallKitSupported = !UIDevice.isSimulator
        
        if isCallKitEnabled && isCallKitSupported && hasAudioPermissions {
            self.callNotificationStyle = .callKit
        }
        else {
            self.callNotificationStyle = .pushNotifications
        }
    }
}
