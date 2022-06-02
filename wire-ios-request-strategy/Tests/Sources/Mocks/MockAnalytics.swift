//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class MockAnalytics: NSObject, AnalyticsType {

    var eventAttributes = [String: [String: NSObject]]()

    public func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        if let attributes = attributes {
            eventAttributes[event] = attributes
        } else {
            eventAttributes.removeValue(forKey: event)
        }
    }

    public func persistedAttributes(for event: String) -> [String: NSObject]? {
        let value = eventAttributes[event] ?? [:]
        return value
    }

    @objc func tagEvent(_ event: String) {
        taggedEvents.append(event)
    }

    @objc func tagEvent(_ event: String, attributes: [String: NSObject]) {
        taggedEventsWithAttributes.append(EventWithAttributes(event: event, attributes: attributes))
    }

    @objc func upload() {
        uploadCallCount += 1
    }

    var taggedEvents = [String]()
    var taggedEventsWithAttributes = [EventWithAttributes]()
    var uploadCallCount = 0
}

// MARK: - Helpers

struct EventWithAttributes: Equatable {
    let event: String
    let attributes: [String: NSObject]
}

func == (lhs: EventWithAttributes, rhs: EventWithAttributes) -> Bool {
    return lhs.event == rhs.event && lhs.attributes == rhs.attributes
}
