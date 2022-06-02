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
import WireTransport

@objc class MockBackgroundActivityManager: NSObject, BackgroundActivityManager {

    var backgroundTimeRemaining: TimeInterval = 10

    var applicationState: UIApplication.State = .active

    // MARK: - BackgroundActivityManager

    @objc public var startedTasks = [String]()
    func beginBackgroundTask(withName name: String?, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        startedTasks.append(name ?? "NO-NAME")
        return UIBackgroundTaskIdentifier(rawValue: startedTasks.count)
    }

    @objc public var endedTasks = [Int]()
    func endBackgroundTask(_ task: UIBackgroundTaskIdentifier) {
        endedTasks.append(task.rawValue)
    }
}
