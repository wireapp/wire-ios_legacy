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

private let AVSLogMessageNotification = Notification.Name("AVSLogMessageNotification")

@objc
public protocol AVSLogger: AnyObject {

    @objc(logMessage:)
    func log(message: String)

}

public extension SessionManager {

    @objc
    static func addLogger(_ logger: AVSLogger) -> Any {
        return SelfUnregisteringNotificationCenterToken(NotificationCenter.default.addObserver(forName: AVSLogMessageNotification, object: nil, queue: nil) { [weak logger] (note) in
            guard let message = note.userInfo?["message"] as? String else { return }
            logger?.log(message: message)
        })
    }

    @objc
    static func logAVS(message: String) {
        NotificationCenter.default.post(name: AVSLogMessageNotification, object: nil, userInfo: ["message": message])
    }

}
