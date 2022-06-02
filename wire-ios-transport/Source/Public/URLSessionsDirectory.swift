////
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objc public protocol URLSessionsDirectory: NSObjectProtocol {
    @objc var foregroundSession: ZMURLSession { get }
    @objc var backgroundSession: ZMURLSession { get }
    @objc var voipSession: ZMURLSession { get }
    @objc var allSessions: [ZMURLSession] { get }
}

@objcMembers public class CurrentURLSessionsDirectory: NSObject, URLSessionsDirectory {
    public var foregroundSession: ZMURLSession
    public var backgroundSession: ZMURLSession
    public var voipSession: ZMURLSession
    public var allSessions: [ZMURLSession] {
        return [foregroundSession, backgroundSession, voipSession]
    }

    @objc public init(foregroundSession: ZMURLSession, backgroundSession: ZMURLSession, voipSession: ZMURLSession) {
        self.foregroundSession = foregroundSession
        self.backgroundSession = backgroundSession
        self.voipSession = voipSession
    }
}

extension CurrentURLSessionsDirectory: TearDownCapable {
    public func tearDown() {
        foregroundSession.tearDown()
        backgroundSession.tearDown()
        voipSession.tearDown()
    }
}
