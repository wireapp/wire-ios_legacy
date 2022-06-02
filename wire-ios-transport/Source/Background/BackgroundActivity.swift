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

import UIKit

/**
 * A token that represents an active background task.
 */

fileprivate var activityCounter = 0 
fileprivate let activityCounterQueue = DispatchQueue(label: "wire-transport.background-activity-counter")

@objc public class BackgroundActivity: NSObject {

    /// The name of the task, used for debugging purposes.
    @objc public let name: String
    /// Globally unique index of background activity
    public let index: Int

    /// The block of code called from the main thead when the background timer is about to expire.
    @objc public var expirationHandler: (() -> Void)?

    init(name: String, expirationHandler: (() -> Void)?) {
        self.name = name
        self.expirationHandler = expirationHandler
        // Increment counter with overflow (used in .description)
        self.index = activityCounterQueue.sync {
            activityCounter &+= 1
            return activityCounter
        }
    }

    // MARK: - Execution

    /**
     * Executes the task.
     * - parameter block: The block to execute with extended lifetime.
     * - parameter activity: A reference to the current activity, so you can stop it before your block returns.
     *
     * You can take advantage of this method to make sure you don't execute code when background execution
     * is no longer available, with nil-coleascing.
     *
     * For example, when you request:
     *
     * ~~~swift
     * BackgroundActivityFactory.shared.startBackgroundActivity(withName: "Test")?.execute {
     *     defer { BackgroundActivityFactory.shared.endBackgroundActivity($0) }
     *     // perform the long task
     *     print("Hello background world")
     * }
     * ~~~
     *
     * If the app is being suspended, the code will not be executed at all.
     */

    @objc(executeBlock:)
    public func execute(block: @escaping (_ activity: BackgroundActivity) -> Void) {
        block(self)
    }

    // MARK: - Hashable

    public override var hash: Int {
        return ObjectIdentifier(self).hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherActivity = object as? BackgroundActivity else {
            return false
        }

        return ObjectIdentifier(self) == ObjectIdentifier(otherActivity)
    }
    
    override public var description: String {
        return "<BackgroundActivity [\(index)]: \(name)>"
    }
}
