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

@objc protocol AnalyticsProvider: NSObjectProtocol {
    var isOptedOut: Bool { get set }

    /// Record an event with optional attributes.
    func tagEvent(_ event: String, attributes: [String : Any])

    /// Set a custom dimension
    func setSuperProperty(_ name: String, value: Any?)


    /// Force the AnalyticsProvider to process the queued data immediately
    ///
    /// - Parameter completion: an optional completion handler for when the flush has completed.
    func flush(completion: (() -> Void)?)
}
