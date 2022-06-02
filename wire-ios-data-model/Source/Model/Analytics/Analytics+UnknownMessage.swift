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

private let unknownMessageEventName = "debug.compatibility_unknown_message"

extension AnalyticsType {

    /// This method should be used to track messages which are not reported to 
    /// be `known`, c.f. `knownMessage` in `ZMGenericMessage+Utils.m`.
    func tagUnknownMessageReceived() {
        tagEvent(unknownMessageEventName)
    }

}

/// Objective-C compatibility wrapper for the unknown message event
class UnknownMessageAnalyticsTracker: NSObject {

    @objc(tagUnknownMessageWithAnalytics:)
    class func tagUnknownMessage(with analytics: AnalyticsType?) {
        analytics?.tagUnknownMessageReceived()
    }

}
