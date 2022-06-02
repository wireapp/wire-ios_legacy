//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import WireRequestStrategy
import Foundation

protocol PushNotificationStrategyDelegate: AnyObject {

    func pushNotificationStrategy(_ strategy: PushNotificationStrategy, didFetchEvents events: [ZMUpdateEvent])
    func pushNotificationStrategyDidFinishFetchingEvents(_ strategy: PushNotificationStrategy)

}

final class PushNotificationStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource, UpdateEventProcessor {

    // MARK: - Properties
    
    var sync: NotificationStreamSync!
    private var pushNotificationStatus: PushNotificationStatus!
    private var eventProcessor: UpdateEventProcessor!
    private var moc: NSManagedObjectContext!

    weak var delegate: PushNotificationStrategyDelegate?

    var eventDecoder: EventDecoder!
    var eventMOC: NSManagedObjectContext!

    // MARK: - Life cycle

    init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        eventContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        pushNotificationStatus: PushNotificationStatus,
        notificationsTracker: NotificationsTracker?
    ) {
        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )
       
        sync = NotificationStreamSync(
            moc: managedObjectContext,
            notificationsTracker: notificationsTracker,
            delegate: self
        )

        self.eventProcessor = self
        self.pushNotificationStatus = pushNotificationStatus
        self.moc = managedObjectContext
        self.eventDecoder = EventDecoder(eventMOC: eventContext, syncMOC: managedObjectContext)
    }

    // MARK: - Methods
    
    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return nextRequest(for: apiVersion)
    }
    
    public override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isFetchingStreamForAPNS else { return nil }
        return requestGenerators.nextRequest(for: apiVersion)
    }
    
    public var requestGenerators: [ZMRequestGenerator] {
           return [sync]
       }
    
    public var isFetchingStreamForAPNS: Bool {
        return self.pushNotificationStatus.hasEventsToFetch
    }

    func processEventsIfReady() -> Bool {
        return true
    }

    var eventConsumers: [ZMEventConsumer] {
        get {
            return []
        }
        set(newValue) {
        }
    }

    @objc public func storeUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        eventDecoder.decryptAndStoreEvents(updateEvents) { decryptedUpdateEvents in
            self.delegate?.pushNotificationStrategy(self, didFetchEvents: decryptedUpdateEvents)
        }
    }

    @objc public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        // Events will be processed in the foreground
    }

}

// MARK: - Notification stream sync delegate

extension PushNotificationStrategy: NotificationStreamSyncDelegate {

    public func fetchedEvents(_ events: [ZMUpdateEvent], hasMoreToFetch: Bool) {
        var eventIds: [UUID] = []
        var parsedEvents: [ZMUpdateEvent] = []
        var latestEventId: UUID? = nil

        for event in events {
            event.appendDebugInformation("From missing update events transcoder, processUpdateEventsAndReturnLastNotificationIDFromPayload")
            parsedEvents.append(event)

            if let uuid = event.uuid {
                eventIds.append(uuid)
            }

            if !event.isTransient {
                latestEventId = event.uuid
            }
        }

        eventProcessor.storeUpdateEvents(parsedEvents, ignoreBuffer: true)
        pushNotificationStatus.didFetch(eventIds: eventIds, lastEventId: latestEventId, finished: !hasMoreToFetch)

        if !hasMoreToFetch {
            delegate?.pushNotificationStrategyDidFinishFetchingEvents(self)
        }
    }
    
    public func failedFetchingEvents() {
        pushNotificationStatus.didFailToFetchEvents()
    }
}


