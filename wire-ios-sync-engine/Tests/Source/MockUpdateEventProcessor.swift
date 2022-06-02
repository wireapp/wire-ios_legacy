//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

@testable import WireSyncEngine

@objcMembers
public class MockUpdateEventProcessor: NSObject, WireSyncEngine.UpdateEventProcessor {

    public var eventConsumers: [ZMEventConsumer] = []
    public var processedEvents: [ZMUpdateEvent] = []
    public var storedEvents: [ZMUpdateEvent] = []

    public func processEventsIfReady() -> Bool {
        processedEvents.append(contentsOf: storedEvents)
        storedEvents = []
        return false
    }

    public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        processedEvents.append(contentsOf: updateEvents)
    }

    public func storeUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        storedEvents.append(contentsOf: updateEvents)
    }

}
