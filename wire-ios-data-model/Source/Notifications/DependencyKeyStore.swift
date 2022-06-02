//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

private var zmLog = ZMSLog(tag: "DependencyKeyStore")

struct Observable {

    private let affectingKeyStore: DependencyKeyStore
    let classIdentifier: String
    private let affectingKeys: [String: Set<String>]
    private let affectedKeys: [String: Set<String>]

    /// Keys that we want to report changes for
    var observableKeys: Set<String> {
        return affectingKeyStore.observableKeys[classIdentifier] ?? Set()
    }

    /// Union of observable keys and their affecting keys
    var allKeys: Set<String> {
        return affectingKeyStore.allKeys[classIdentifier] ?? Set()
    }

    init(classIdentifier: String, affectingKeyStore: DependencyKeyStore) {
        self.classIdentifier = classIdentifier
        self.affectingKeyStore = affectingKeyStore
        self.affectingKeys = affectingKeyStore.affectingKeys[classIdentifier] ?? [:]
        self.affectedKeys = affectingKeyStore.effectedKeys[classIdentifier] ?? [:]
    }

    func keyPathsForValuesAffectingValue(for key: String) -> Set<String> {
        return affectingKeys[key] ?? Set()
    }

    func observableKeysAffectedByValue(for key: String) -> Set<String> {
        var keys = affectedKeys[key] ?? Set()
        if observableKeys.contains(key) {
            keys.insert(key)
        }
        return keys
    }
}

/// Maps the observable keys to affectedKeys and vice versa
/// You should create this only once
class DependencyKeyStore {

    /// Keys that are needed to create a changeInfo
    let observableKeys: [String: Set<String>]

    /// All keys that will create a changeInfo
    let allKeys: [String: Set<String>]

    /// Maps observable keys to keys whose values affect them
    let affectingKeys: [String: [String: Set<String>]]

    /// Maps keys that affect the observables to their respective observables
    let effectedKeys: [String: [String: Set<String>]]

    /// Returns a store mapping observable keys and their affecting keys
    /// @param classIdentifier: Identifiers for each class, e.g. entityName
    init(classIdentifiers: [String]) {
        let observable = classIdentifiers.mapToDictionary {DependencyKeyStore.setupObservableKeys(classIdentifier: $0)}
        let affecting = classIdentifiers.mapToDictionary {DependencyKeyStore.setupAffectedKeys(classIdentifier: $0, observableKeys: observable[$0]!)}
        let all = classIdentifiers.mapToDictionary {DependencyKeyStore.setupAllKeys(observableKeys: observable[$0]!, affectingKeys: affecting[$0]!)}
        effectedKeys = classIdentifiers.mapToDictionary {DependencyKeyStore.setupEffectedKeys(affectingKeys: affecting[$0]!)}

        self.observableKeys = observable
        self.affectingKeys = affecting
        self.allKeys = all
    }

    /// When adding objects that are to be observed, add keys that are supposed to be reported on in here
    private static func setupObservableKeys(classIdentifier: String) -> Set<String> {
        switch classIdentifier {
        case ZMConversation.entityName():
            return ZMConversation.observableKeys
        case ZMUser.entityName():
            return ZMUser.observableKeys
        case ZMConnection.entityName():
            return Set([#keyPath(ZMConnection.status)])
        case UserClient.entityName():
            return UserClient.observableKeys
        case ZMMessage.entityName():
            return ZMMessage.observableKeys
        case ZMAssetClientMessage.entityName():
            return ZMAssetClientMessage.observableKeys
        case ZMClientMessage.entityName():
            return ZMClientMessage.observableKeys
        case ZMTextMessage.entityName(), ZMImageMessage.entityName():
            return Set()
        case ZMSystemMessage.entityName():
            return ZMSystemMessage.observableKeys
        case Reaction.entityName():
            return Set([#keyPath(Reaction.users)])
        case ZMGenericMessageData.entityName():
            return Set()
        case Team.entityName():
            return Team.observableKeys
        case Member.entityName():
            return Set()
        case Label.entityName():
            return Label.observableKeys
        case ParticipantRole.entityName():
            return ParticipantRole.observableKeys
        case ButtonState.entityName():
            return Set([#keyPath(ButtonState.stateValue), #keyPath(ButtonState.isExpired)])
        default:
            zmLog.warn("There are no observable keys defined for \(classIdentifier)")
            return Set()
        }
    }

    /// Creates a dictionary mapping the observable keys to keys affecting their values
    /// ["foo" : keysAffectingValueForKey(foo), "bar" : keysAffectingValueForKey(bar)]
    private static func setupAffectedKeys(classIdentifier: String, observableKeys: Set<String>) -> [String: Set<String>] {
        switch classIdentifier {
        case ZMConversation.entityName():
            return observableKeys.mapToDictionary {ZMConversation.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMUser.entityName():
            return observableKeys.mapToDictionary {ZMUser.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMConnection.entityName():
            return [:]
        case UserClient.entityName():
            return observableKeys.mapToDictionary {UserClient.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMMessage.entityName():
            return observableKeys.mapToDictionary {ZMMessage.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMAssetClientMessage.entityName():
            return observableKeys.mapToDictionary {ZMAssetClientMessage.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMSystemMessage.entityName():
            return observableKeys.mapToDictionary {ZMSystemMessage.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMClientMessage.entityName():
            return observableKeys.mapToDictionary {ZMClientMessage.keyPathsForValuesAffectingValue(forKey: $0)}
        case Reaction.entityName():
            return observableKeys.mapToDictionary {Reaction.keyPathsForValuesAffectingValue(forKey: $0)}
        case ZMGenericMessageData.entityName():
            return observableKeys.mapToDictionary {ZMGenericMessageData.keyPathsForValuesAffectingValue(forKey: $0)}
        case Team.entityName():
            return observableKeys.mapToDictionary {Team.keyPathsForValuesAffectingValue(forKey: $0)}
        case Member.entityName():
            return [:]
        case Label.entityName():
            return observableKeys.mapToDictionary {Label.keyPathsForValuesAffectingValue(forKey: $0)}
        case ParticipantRole.entityName():
            return observableKeys.mapToDictionary {ParticipantRole.keyPathsForValuesAffectingValue(forKey: $0)}
        case ButtonState.entityName():
            return observableKeys.mapToDictionary {ButtonState.keyPathsForValuesAffectingValue(forKey: $0)}
        default:
            zmLog.warn("There is no path to affecting keys defined for \(classIdentifier)")
            return [:]
        }
    }

    /// Combines observed keys and all affecting keys in one giant Set
    private static func setupAllKeys(observableKeys: Set<String>, affectingKeys: [String: Set<String>]) -> Set<String> {
        let allAffectingKeys: Set<String> = affectingKeys.reduce(Set()) {$0.union($1.value)}
        return observableKeys.union(allAffectingKeys)
    }

    /// Creates a dictionary mapping keys affecting values for key into the opposite direction
    /// ["foo" : Set("affectingKey1", "affectingKey2")] --> ["affectingKey1" : Set("foo"), "affectingKey2" : Set("foo")]
    private static func setupEffectedKeys(affectingKeys: [String: Set<String>]) -> [String: Set<String>] {
        var allEffectedKeys = [String: Set<String>]()
        affectingKeys.forEach { key, values in
            values.forEach {
                allEffectedKeys[$0] = (allEffectedKeys[$0] ?? Set()).union(Set(arrayLiteral: key))
            }
        }
        return allEffectedKeys
    }

    /// Returns keyPathsForValuesAffectingValueForKey for specified `key`
    func keyPathsForValuesAffectingValue(_ classIdentifier: String, key: String) -> Set<String> {
        return affectingKeys[classIdentifier]?[key] ?? Set()
    }

    /// Returns the inverse of keyPathsForValuesAffectingValueForKey, all observable keys that are affected by `key`
    ///
    /// - Parameters:
    ///   - classIdentifier: the class's id, e.g. "Conversation"
    ///   - key: the key, e.g. "participantRoles.role"
    /// - Returns: the inverse of keyPathsForValuesAffectingValueForKey, all observable keys that are affected by `key`
    func observableKeysAffectedByValue(_ classIdentifier: String, key: String) -> Set<String> {
        var keys = effectedKeys[classIdentifier]?[key] ?? Set()
        if let otherKeys = observableKeys[classIdentifier], otherKeys.contains(key) {
            keys.insert(key)
        }
        return keys
    }

    /// Returns a set of keys that need to be present in the changesValues of the object so that the object changes will be included in the changeInfo of the specified classIdentifier
    func requiredKeysForIncludingRawChanges(classIdentifier: String, for object: ZMManagedObject) -> Set<String> {
        switch (classIdentifier, object) {
        case (ZMUser.entityName(), is UserClient):
            return Set([ZMUserClientTrustedKey, ZMUserClientTrusted_ByKey])
        default:
            return Set()
        }
    }
}
