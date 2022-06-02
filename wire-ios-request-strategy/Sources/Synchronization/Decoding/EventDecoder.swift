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
import WireCryptobox
import WireDataModel

private let zmLog = ZMSLog(tag: "EventDecoder")

/// Key used in persistent store metadata
private let previouslyReceivedEventIDsKey = "zm_previouslyReceivedEventIDsKey"

/// Holds a list of received event IDs
@objc public protocol PreviouslyReceivedEventIDsCollection: NSObjectProtocol {
    func discardListOfAlreadyReceivedPushEventIDs()
}

/// Decodes and stores events from various sources to be processed later
@objcMembers public final class EventDecoder: NSObject {

    public typealias ConsumeBlock = (([ZMUpdateEvent]) -> Void)

    static var BatchSize: Int {
        if let testingBatchSize = testingBatchSize {
            return testingBatchSize
        }
        return 500
    }

    /// Set this for testing purposes only
    public static var testingBatchSize: Int?

    unowned let eventMOC: NSManagedObjectContext
    unowned let syncMOC: NSManagedObjectContext

    fileprivate typealias EventsWithStoredEvents = (storedEvents: [StoredUpdateEvent], updateEvents: [ZMUpdateEvent])

    public init(eventMOC: NSManagedObjectContext, syncMOC: NSManagedObjectContext) {
        self.eventMOC = eventMOC
        self.syncMOC = syncMOC
        super.init()
        self.eventMOC.performGroupedBlockAndWait {
            self.createReceivedPushEventIDsStoreIfNecessary()
        }
    }
}

// MARK: - Process events
extension EventDecoder {

    /// Decrypts passed in events and stores them in chronological order in a persisted database,
    /// it then saves the database and cryptobox
    ///
    /// - Parameters:
    ///   - events: Encrypted events
    public func decryptAndStoreEvents(_ events: [ZMUpdateEvent], block: ConsumeBlock? = nil) {
        var lastIndex: Int64?
        var decryptedEvents: [ZMUpdateEvent] = []

        eventMOC.performGroupedBlockAndWait {

            self.storeReceivedPushEventIDs(from: events)
            let filteredEvents = self.filterAlreadyReceivedEvents(from: events)

            // Get the highest index of events in the DB
            lastIndex = StoredUpdateEvent.highestIndex(self.eventMOC)

            guard let index = lastIndex else { return }
            decryptedEvents = self.decryptAndStoreEvents(filteredEvents, startingAtIndex: index)
        }

        if !events.isEmpty {
            Logging.eventProcessing.info("Decrypted/Stored \( events.count) event(s)")
        }

        block?(decryptedEvents)
    }

    /// Process previously stored and decrypted events by repeatedly calling the the consume block until
    /// all the stored events have been processed. If the app crashes while processing the events, they
    /// can be recovered from the database.
    ///
    /// - Parameters:
    ///   - encryptionKeys: Keys to be used to decrypt events.
    ///   - block: Event consume block which is called once for every stored event.
    public func processStoredEvents(with encryptionKeys: EncryptionKeys? = nil, _ block: ConsumeBlock) {
        process(with: encryptionKeys, block, firstCall: true)
    }

    /// Decrypts and stores the decrypted events as `StoreUpdateEvent` in the event database.
    /// The encryption context is only closed after the events have been stored, which ensures
    /// they can be decrypted again in case of a crash.
    /// - parameter events The new events that should be decrypted and stored in the database.
    /// - parameter startingAtIndex The startIndex to be used for the incrementing sortIndex of the stored events.
    /// - Returns: Decrypted events
    fileprivate func decryptAndStoreEvents(_ events: [ZMUpdateEvent], startingAtIndex startIndex: Int64) -> [ZMUpdateEvent] {
        let account = Account(userName: "", userIdentifier: ZMUser.selfUser(in: self.syncMOC).remoteIdentifier)
        let publicKey = try? EncryptionKeys.publicKey(for: account)
        var decryptedEvents: [ZMUpdateEvent] = []

        syncMOC.zm_cryptKeyStore.encryptionContext.perform { [weak self] (sessionsDirectory) -> Void in
            guard let `self` = self else { return }

            decryptedEvents = events.compactMap { event -> ZMUpdateEvent? in
                if event.type == .conversationOtrMessageAdd || event.type == .conversationOtrAssetAdd {
                    return sessionsDirectory.decryptAndAddClient(event, in: self.syncMOC)
                } else {
                    return event
                }
            }

            // This call has to be synchronous to ensure that we close the
            // encryption context only if we stored all events in the database

            // Insert the decrypted events in the event database using a `storeIndex`
            // incrementing from the highest index currently stored in the database
            // The encryptedPayload property is encrypted using the public key
            for (idx, event) in decryptedEvents.enumerated() {
                _ = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: Int64(idx) + startIndex + 1, publicKey: publicKey)
            }

            self.eventMOC.saveOrRollback()
        }

        return decryptedEvents
    }

    // Processes the stored events in the database in batches of size EventDecoder.BatchSize` and calls the `consumeBlock` for each batch.
    // After the `consumeBlock` has been called the stored events are deleted from the database.
    // This method terminates when no more events are in the database.
    private func process(with encryptionKeys: EncryptionKeys?, _ consumeBlock: ConsumeBlock, firstCall: Bool) {
        let events = fetchNextEventsBatch(with: encryptionKeys)
        guard events.storedEvents.count > 0 else {
            if firstCall {
                consumeBlock([])
            }
            return
        }

        processBatch(events.updateEvents, storedEvents: events.storedEvents, block: consumeBlock)
        process(with: encryptionKeys, consumeBlock, firstCall: false)
    }

    /// Calls the `ComsumeBlock` and deletes the respective stored events subsequently.
    private func processBatch(_ events: [ZMUpdateEvent], storedEvents: [NSManagedObject], block: ConsumeBlock) {
        if !events.isEmpty {
            Logging.eventProcessing.info("Forwarding \(events.count) event(s) to consumers")
        }

        block(filterInvalidEvents(from: events))

        eventMOC.performGroupedBlockAndWait {
            storedEvents.forEach(self.eventMOC.delete(_:))
            self.eventMOC.saveOrRollback()
        }
    }

    /// Fetches and returns the next batch of size `EventDecoder.BatchSize`
    /// of `StoredEvents` and `ZMUpdateEvent`'s in a `EventsWithStoredEvents` tuple.
    private func fetchNextEventsBatch(with encryptionKeys: EncryptionKeys?) -> EventsWithStoredEvents {
        var (storedEvents, updateEvents)  = ([StoredUpdateEvent](), [ZMUpdateEvent]())

        eventMOC.performGroupedBlockAndWait {
            storedEvents = StoredUpdateEvent.nextEvents(self.eventMOC, batchSize: EventDecoder.BatchSize)
            updateEvents = StoredUpdateEvent.eventsFromStoredEvents(storedEvents, encryptionKeys: encryptionKeys)
        }
        return (storedEvents: storedEvents, updateEvents: updateEvents)
    }

}

// MARK: - List of already received event IDs
extension EventDecoder {

    /// create event ID store if needed
    fileprivate func createReceivedPushEventIDsStoreIfNecessary() {
        if self.eventMOC.persistentStoreMetadata(forKey: previouslyReceivedEventIDsKey) as? [String] == nil {
            self.eventMOC.setPersistentStoreMetadata(array: [String](), key: previouslyReceivedEventIDsKey)
        }
    }

    /// List of already received event IDs
    fileprivate var alreadyReceivedPushEventIDs: Set<UUID> {
        let array = self.eventMOC.persistentStoreMetadata(forKey: previouslyReceivedEventIDsKey) as! [String]
        return Set(array.compactMap { UUID(uuidString: $0) })
    }

    /// List of already received event IDs as strings
    fileprivate var alreadyReceivedPushEventIDsStrings: Set<String> {
        return Set(self.eventMOC.persistentStoreMetadata(forKey: previouslyReceivedEventIDsKey) as! [String])
    }

    /// Store received event IDs
    fileprivate func storeReceivedPushEventIDs(from: [ZMUpdateEvent]) {
        let uuidToAdd = from
            .filter { $0.source == .pushNotification }
            .compactMap { $0.uuid }
            .map { $0.transportString() }
        let allUuidStrings = self.alreadyReceivedPushEventIDsStrings.union(uuidToAdd)

        self.eventMOC.setPersistentStoreMetadata(array: Array(allUuidStrings), key: previouslyReceivedEventIDsKey)
    }

    /// Filters out events that have been received before
    fileprivate func filterAlreadyReceivedEvents(from: [ZMUpdateEvent]) -> [ZMUpdateEvent] {
        let eventIDsToDiscard = self.alreadyReceivedPushEventIDs
        return from.compactMap { event -> ZMUpdateEvent? in
            if event.source != .pushNotification, let uuid = event.uuid {
                return eventIDsToDiscard.contains(uuid) ? nil : event
            } else {
                return event
            }
        }
    }

    /// Filters out events that shouldn't be processed
    fileprivate func filterInvalidEvents(from events: [ZMUpdateEvent]) -> [ZMUpdateEvent] {
        let selfConversation = ZMConversation.selfConversation(in: syncMOC)
        let selfUser = ZMUser.selfUser(in: syncMOC)

        return events.filter { event in
            // The only message we process arriving in the self conversation from other users is availability updates
            if event.conversationUUID == selfConversation.remoteIdentifier, event.senderUUID != selfUser.remoteIdentifier, let genericMessage = GenericMessage(from: event) {
                return genericMessage.hasAvailability
            }

            return true
        }
    }
}

@objc extension EventDecoder: PreviouslyReceivedEventIDsCollection {

    /// Discards the list of already received events
    public func discardListOfAlreadyReceivedPushEventIDs() {
        self.eventMOC.performGroupedBlockAndWait {
            self.eventMOC.setPersistentStoreMetadata(array: [String](), key: previouslyReceivedEventIDsKey)
        }
    }
}
