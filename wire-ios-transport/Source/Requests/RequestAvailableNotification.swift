//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


private let RequestsAvailableNotificationName = "RequestAvailableNotification"


@objc(ZMRequestAvailableObserver) public protocol RequestAvailableObserver : NSObjectProtocol {
    
    func newRequestsAvailable()
    
}

/// ZMRequestAvailableNotification is used by transport to signal the operation loop that
/// there are new potential requests available to process.
@objc(ZMRequestAvailableNotification) public class RequestAvailableNotification : NSObject {
    
    @objc public static func notifyNewRequestsAvailable(_ sender: NSObjectProtocol?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: RequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func addObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.addObserver(observer, selector: #selector(RequestAvailableObserver.newRequestsAvailable), name: NSNotification.Name(rawValue: RequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func removeObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: RequestsAvailableNotificationName), object: nil)
    }
    
}
