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
import CoreData

@objc(StoredUpdateEvent)
public final class StoredUpdateEvent: NSManagedObject {

    static let entityName =  "StoredUpdateEvent"
    static let SortIndexKey = "sortIndex"
    /// The key under which the event payload is encrypted by the public key.
    static internal let encryptedPayloadKey = "encryptedPayload"

    @NSManaged var uuidString: String?
    @NSManaged var debugInformation: String?
    @NSManaged var isTransient: Bool
    @NSManaged var payload: NSDictionary?
    @NSManaged var isEncrypted: Bool
    @NSManaged var source: Int16
    @NSManaged var sortIndex: Int64

    static func insertNewObject(_ context: NSManagedObjectContext) -> StoredUpdateEvent? {
        return NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: context) as? StoredUpdateEvent
    }

    /// Maps a passed in `ZMUpdateEvent` to a `StoredUpdateEvent` which is persisted in a database
    /// - Parameters:
    ///   - event: received events
    ///   - managedObjectContext: current managedObjectContext
    ///   - index: the passed in `index` is used to enumerate events to be able to fetch and sort them later on in the order they were received
    ///   - publicKey: the publicKey which will be used to encrypt update events
    /// - Returns: storedEvent which will be persisted in a database
    public static func encryptAndCreate(_ event: ZMUpdateEvent, managedObjectContext: NSManagedObjectContext, index: Int64, publicKey: SecKey? = nil) -> StoredUpdateEvent? {
        guard let storedEvent = StoredUpdateEvent.insertNewObject(managedObjectContext) else { return nil }
        storedEvent.debugInformation = event.debugInformation
        storedEvent.isTransient = event.isTransient
        storedEvent.source = Int16(event.source.rawValue)
        storedEvent.sortIndex = index
        storedEvent.uuidString = event.uuid?.transportString()
        storedEvent.payload = encryptIfNeeded(eventPayload: event.payload as NSDictionary, publicKey: publicKey)
        storedEvent.isEncrypted = publicKey != nil

        return storedEvent
    }

    /// Encrypts the passed payload if publicKey exists. Otherwise, returns the passed event payload
    /// - Parameters:
    ///   - eventPayload: the envent payload
    ///   - publicKey: publicKey which will be used to encrypt eventPayload
    /// - Returns: a dictionary which contains encrypted or unencrypted payload
    private static func encryptIfNeeded(eventPayload: NSDictionary, publicKey: SecKey?) -> NSDictionary? {
        guard let key = publicKey else {
            return eventPayload
        }
        guard let data = try? JSONSerialization.data(withJSONObject: eventPayload, options: []),
            let encryptedData = SecKeyCreateEncryptedData(key,
                                                          .eciesEncryptionCofactorX963SHA256AESGCM,
                                                          data as CFData,
                                                          nil) else {
                                                            return nil
        }
        return NSDictionary(dictionary: [encryptedPayloadKey: encryptedData])
    }

    /// Returns stored events sorted by and up until (including) the defined `stopIndex`
    /// Returns a maximum of `batchSize` events at a time
    public static func nextEvents(_ context: NSManagedObjectContext, batchSize: Int) -> [StoredUpdateEvent] {
        let fetchRequest = NSFetchRequest<StoredUpdateEvent>(entityName: self.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: StoredUpdateEvent.SortIndexKey, ascending: true)]
        fetchRequest.fetchLimit = batchSize
        fetchRequest.returnsObjectsAsFaults = false
        let result = context.fetchOrAssert(request: fetchRequest)
        return result
    }

    /// Returns the highest index of all stored events
    public static func highestIndex(_ context: NSManagedObjectContext) -> Int64 {
        let fetchRequest = NSFetchRequest<StoredUpdateEvent>(entityName: self.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: StoredUpdateEvent.SortIndexKey, ascending: false)]
        fetchRequest.fetchBatchSize = 1
        let result = context.fetchOrAssert(request: fetchRequest)
        return result.first?.sortIndex ?? 0
    }

    /// Maps passed in objects of type `StoredUpdateEvent` to `ZMUpdateEvent`
    public static func eventsFromStoredEvents(_ storedEvents: [StoredUpdateEvent], encryptionKeys: EncryptionKeys? = nil) -> [ZMUpdateEvent] {
        let events: [ZMUpdateEvent] = storedEvents.compactMap {
            var eventUUID: UUID?
            if let uuid = $0.uuidString {
                eventUUID = UUID(uuidString: uuid)
            }

            guard let payload = decryptPayloadIfNeeded(storedEvent: $0, encryptionKeys: encryptionKeys) else {
                return nil
            }
            let decryptedEvent = ZMUpdateEvent.decryptedUpdateEvent(fromEventStreamPayload: payload, uuid: eventUUID, transient: $0.isTransient, source: ZMUpdateEventSource(rawValue: Int($0.source))!)
            if let debugInfo = $0.debugInformation {
                decryptedEvent?.appendDebugInformation(debugInfo)
            }
            return decryptedEvent
        }
        return events
    }

    /// Decrypts the passed stored event payload if the isEncrypted property is true.
    /// - Parameters:
    ///   - storedEvent: the stored event
    ///   - encryptionKeys: keys to be used to decrypt the stored event payload
    /// - Returns: a dictionary which contains decrypted payload
    private static func decryptPayloadIfNeeded(storedEvent: StoredUpdateEvent, encryptionKeys: EncryptionKeys?) -> NSDictionary? {
        if !storedEvent.isEncrypted {
            return storedEvent.payload
        }

        guard let keys = encryptionKeys,
            let encryptedPayload = storedEvent.payload?[encryptedPayloadKey] as? Data,
            let decryptedData = SecKeyCreateDecryptedData(keys.privateKey,
                                                          .eciesEncryptionCofactorX963SHA256AESGCM,
                                                          encryptedPayload as CFData,
                                                          nil) else {
                                                            return nil
        }

      return try? JSONSerialization.jsonObject(with: decryptedData as Data, options: []) as? NSDictionary
    }
}
