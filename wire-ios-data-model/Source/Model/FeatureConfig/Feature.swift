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

private let zmLog = ZMSLog(tag: "Feature")

@objcMembers
public class Feature: ZMManagedObject {

    // MARK: - Types

    // IMPORTANT
    //
    // Only add new cases to these enums. Deleting or modifying the raw values
    // of these cases may lead to a corrupt database.

    public enum Name: String, Codable, CaseIterable {
        case appLock
        case conferenceCalling
        case fileSharing
        case selfDeletingMessages
        case conversationGuestLinks
        case classifiedDomains
        case digitalSignature
    }

    public enum Status: String, Codable {
        case enabled
        case disabled
    }

    // MARK: - Properties

    @NSManaged private var nameValue: String
    @NSManaged private var statusValue: String
    @NSManaged private var configData: Data?
    @NSManaged public var needsToNotifyUser: Bool
    @NSManaged var hasInitialDefault: Bool

    public var config: Data? {
        get {
            return configData
        }

        set {
            if hasBeenUpdatedFromBackend {
                updateNeedsToNotifyUser(oldData: configData, newData: newValue)
            }
            configData = newValue
        }
    }

    public var name: Name {
        get {
            guard let name = Name(rawValue: nameValue) else {
                fatalError("Failed to decode nameValue: \(nameValue)")
            }

            return name
        }

        set {
            nameValue = newValue.rawValue
        }
    }

    public var status: Status {
        get {
            guard let status = Status(rawValue: statusValue) else {
                fatalError("Failed to decode statusValue: \(statusValue)")
            }

            return status
        }

        set {
            if hasBeenUpdatedFromBackend {
                updateNeedsToNotifyUser(oldStatus: status, newStatus: newValue)
            }
            statusValue = newValue.rawValue
        }
    }

    /// Whether the feature has been updated from backend
    private var hasBeenUpdatedFromBackend: Bool {
        return !statusValue.isEmpty && !hasInitialDefault
    }

    // MARK: - Methods

    public override static func entityName() -> String {
        return "Feature"
    }

    public override static func sortKey() -> String {
        return #keyPath(Feature.nameValue)
    }

    /// Fetch the instance for the given name.
    ///
    /// If more than one instance is found, this method will crash.
    ///
    /// - Parameters:
    ///     - name: The name of the feature to fetch.
    ///     - context: The context in which to fetch the instance.
    ///
    /// - Returns: An instance, if it exists, otherwise `nil`.

    public static func fetch(name: Name,
                             context: NSManagedObjectContext) -> Feature? {

        let fetchRequest = NSFetchRequest<Feature>(entityName: Feature.entityName())
        fetchRequest.predicate = NSPredicate(format: "nameValue == %@", name.rawValue)
        fetchRequest.fetchLimit = 2

        let results = context.fetchOrAssert(request: fetchRequest)
        require(results.count <= 1, "More than instance for feature: \(name.rawValue)")
        return results.first
    }

    /// Update the feature instance with the given name.
    ///
    /// - Parameters:
    ///     - name: The name of the feature to update.
    ///     - context: The context in which to fetch the instance.
    ///     - changes: A closure to mutate the fetched instance.

    public static func updateOrCreate(havingName name: Name,
                                      in context: NSManagedObjectContext,
                                      changes: @escaping (Feature) -> Void) {

        // There should be at most one instance per feature, so only allow modifications
        // on a single context to avoid race conditions.
        assert(context.zm_isSyncContext, "Modifications of `Feature` can only occur on the sync context")

        context.performGroupedAndWait { context in
            if let existing = fetch(name: name, context: context) {
                changes(existing)
                existing.hasInitialDefault = false
            } else {
                let feature = Feature.insertNewObject(in: context)
                feature.name = name
                changes(feature)
                feature.hasInitialDefault = true
            }

            context.saveOrRollback()
        }
    }

    private func updateNeedsToNotifyUser(oldStatus: Status, newStatus: Status) {
        let hasStatusChanged = oldStatus != newStatus

        switch name {
        case .conferenceCalling:
            needsToNotifyUser = hasStatusChanged && newStatus == .enabled

        case .fileSharing, .selfDeletingMessages, .conversationGuestLinks:
            needsToNotifyUser = hasStatusChanged

        default:
            break
        }
    }

    private func updateNeedsToNotifyUser(oldData: Data?, newData: Data?) {
        switch name {
        case .appLock:
            let decoder = JSONDecoder()

            guard
                !needsToNotifyUser,
                let oldValue = oldData,
                let newValue = newData,
                let oldConfig = try? decoder.decode(Feature.AppLock.Config.self, from: oldValue),
                let newConfig = try? decoder.decode(Feature.AppLock.Config.self, from: newValue)
            else {
                return
            }

            needsToNotifyUser = oldConfig.enforceAppLock != newConfig.enforceAppLock

        case .selfDeletingMessages:
            let decoder = JSONDecoder()

            guard
                !needsToNotifyUser,
                let oldValue = oldData,
                let newValue = newData,
                let oldConfig = try? decoder.decode(Feature.SelfDeletingMessages.Config.self, from: oldValue),
                let newConfig = try? decoder.decode(Feature.SelfDeletingMessages.Config.self, from: newValue)
            else {
                return
            }

            needsToNotifyUser = oldConfig.enforcedTimeoutSeconds != newConfig.enforcedTimeoutSeconds

        case .conferenceCalling, .fileSharing, .conversationGuestLinks, .classifiedDomains, .digitalSignature:
            return
        }
    }
}
