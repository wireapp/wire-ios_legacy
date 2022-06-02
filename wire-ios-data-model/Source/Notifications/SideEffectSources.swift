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

typealias ObjectAndChanges = [ZMManagedObject: Changes]

protocol SideEffectSource {

    /// Returns a map of objects and keys that are affected by an update and it's resulting changedValues mapped by classIdentifier
    /// [classIdentifier : [affectedObject: changedKeys]]
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges

    /// Returns a map of objects and keys that are affected by an insert or deletion mapped by classIdentifier
    /// [classIdentifier : [affectedObject: changedKeys]]
    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges
}

extension ZMManagedObject {

    /// Returns a map of [classIdentifier : [affectedObject: changedKeys]]
    func byInsertOrDeletionAffectedKeys(for object: ZMManagedObject?, keyStore: DependencyKeyStore, affectedKey: String) -> ObjectAndChanges {
        guard let object = object else { return [:] }
        let classIdentifier = type(of: object).entityName()
        return [object: Changes(changedKeys: keyStore.observableKeysAffectedByValue(classIdentifier, key: affectedKey))]
    }

    /// Returns a map of [classIdentifier : [affectedObject: changedKeys]]
    func byUpdateAffectedKeys(for object: ZMManagedObject?,
                              knownKeys: Set<String>,
                              keyStore: DependencyKeyStore,
                              originalChangeKey: String? = nil,
                              keyMapping: ((String) -> String)) -> ObjectAndChanges {
        guard let object = object else { return [:]}
        let classIdentifier = type(of: object).entityName()

        var changes = changedValues()
        guard !changes.isEmpty || !knownKeys.isEmpty else { return [:] }
        let allKeys = knownKeys.union(changes.keys)

        let mappedKeys: [String] = Array(allKeys).map(keyMapping)
        let keys = mappedKeys.map {
            keyStore.observableKeysAffectedByValue(classIdentifier, key: $0)
            }.reduce(Set()) {$0.union($1)}

        guard !keys.isEmpty ||
            originalChangeKey != nil else { return [:] }

        var originalChanges = [String: NSObject?]()
        if let originalChangeKey = originalChangeKey {
            let requiredKeys = keyStore.requiredKeysForIncludingRawChanges(classIdentifier: classIdentifier, for: self)
            knownKeys.forEach {
                if changes[$0] == nil {
                    changes[$0] = .none as NSObject?
                }
            }
            if requiredKeys.isEmpty || !requiredKeys.isDisjoint(with: changes.keys) {
                originalChanges = [originalChangeKey: [self: changes] as NSObject?]
            }
        }

        return [object: Changes(changedKeys: keys, originalChanges: originalChanges)]
    }
}

extension ZMUser: SideEffectSource {

    var allConversations: [ZMConversation] {
        var conversations = self.participantRoles.compactMap { $0.conversation }
        if let connectedConversation = connection?.conversation {
            conversations.append(connectedConversation)
        }
        return conversations
    }

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        let changes = changedValues()
        guard changes.count > 0 || knownKeys.count > 0 else { return [:] }

        let allKeys = knownKeys.union(changes.keys)

        let conversations = allConversations
        guard conversations.count > 0 else { return  [:] }

        let affectedObjects = conversationChanges(changedKeys: allKeys, conversations: conversations, keyStore: keyStore)
        return affectedObjects
    }

    func conversationChanges(changedKeys: Set<String>, conversations: [ZMConversation], keyStore: DependencyKeyStore) -> ObjectAndChanges {
        var affectedObjects = [ZMManagedObject: Changes]()
        let classIdentifier = ZMConversation.entityName()

        // Get all the changed keys, including the ones in the user that are affected by this change
        let allChangedKeys = changedKeys.reduce(into: Set<String>()) { keys, changedKey in
            keys.formUnion(keyStore.observableKeysAffectedByValue(ZMUser.entityName(), key: changedKey))
        }

        let otherPartKeys = allChangedKeys.map {"\(#keyPath(ZMConversation.participantRoles.user)).\($0)"}
        let selfUserKeys = allChangedKeys.map {"\(#keyPath(ZMConversation.connection)).\(#keyPath(ZMConnection.to)).\($0)"}
        let mappedKeys = otherPartKeys + selfUserKeys
        var keys = mappedKeys.map {keyStore.observableKeysAffectedByValue(classIdentifier, key: $0)}.reduce(Set()) {$0.union($1)}

        conversations.forEach {
            if $0.allUsersTrusted {
                keys.insert(SecurityLevelKey)
            }
            if keys.count > 0 {
                affectedObjects[$0] = Changes(changedKeys: keys)
            }
        }
        return affectedObjects
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        let conversations = allConversations
        guard conversations.count > 0 else { return  [:] }

        let classIdentifier = ZMConversation.entityName()
        let affectedKeys = keyStore.observableKeysAffectedByValue(classIdentifier, key: #keyPath(ZMConversation.localParticipantRoles))
        return Dictionary(keys: conversations,
                                            repeatedValue: Changes(changedKeys: affectedKeys))
    }
}

extension ParticipantRole: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore,
                                knownKeys: Set<String>) -> ObjectAndChanges {
        let keyMapping: ((String) -> String) = {
            "\(#keyPath(ZMConversation.participantRoles)).\($0)"
        }

        let changes = byUpdateAffectedKeys(for: conversation,
                                               knownKeys: knownKeys,
                                               keyStore: keyStore,
                                               keyMapping: keyMapping)

        return changes
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        // delete a ParticipantRole should affects conversation's participants
        return byInsertOrDeletionAffectedKeys(for: conversation,
                                              keyStore: keyStore,
                                              affectedKey: #keyPath(ZMConversation.participantRoles))
    }
}

extension ZMMessage: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        return [:]
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        return byInsertOrDeletionAffectedKeys(for: conversation, keyStore: keyStore, affectedKey: #keyPath(ZMConversation.allMessages))
    }
}

extension ZMConnection: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        let conversationChanges = byUpdateAffectedKeys(for: conversation, knownKeys: knownKeys, keyStore: keyStore, keyMapping: {"\(#keyPath(ZMConversation.connection)).\($0)"})
        let userChanges = byUpdateAffectedKeys(for: to, knownKeys: knownKeys, keyStore: keyStore, keyMapping: {"\(#keyPath(ZMConversation.connection)).\($0)"})
        return conversationChanges.updated(other: userChanges)
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        return [:]
    }
}

extension UserClient: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        return byUpdateAffectedKeys(for: user, knownKeys: knownKeys, keyStore: keyStore, originalChangeKey: "clientChanges", keyMapping: {"\(#keyPath(ZMUser.clients)).\($0)"})
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        return byInsertOrDeletionAffectedKeys(for: user, keyStore: keyStore, affectedKey: #keyPath(ZMUser.clients))
    }
}

extension Reaction: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        return byUpdateAffectedKeys(for: message, knownKeys: knownKeys, keyStore: keyStore, originalChangeKey: "reactionChanges", keyMapping: {"\(#keyPath(ZMMessage.reactions)).\($0)"})
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        return byInsertOrDeletionAffectedKeys(for: message, keyStore: keyStore, affectedKey: #keyPath(ZMMessage.reactions))
    }
}

extension ButtonState: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        return byUpdateAffectedKeys(for: message, knownKeys: knownKeys, keyStore: keyStore, originalChangeKey: MessageChangeInfo.ButtonStateChangeInfoKey, keyMapping: {"\(#keyPath(ZMClientMessage.buttonStates)).\($0)"})
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        return byInsertOrDeletionAffectedKeys(for: message, keyStore: keyStore, affectedKey: #keyPath(ZMClientMessage.buttonStates))
    }
}

extension ZMGenericMessageData: SideEffectSource {

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        return byUpdateAffectedKeys(for: message ?? asset, knownKeys: knownKeys, keyStore: keyStore, keyMapping: {"\(#keyPath(ZMClientMessage.dataSet)).\($0)"})
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        return byInsertOrDeletionAffectedKeys(for: message ?? asset, keyStore: keyStore, affectedKey: #keyPath(ZMClientMessage.dataSet))
    }
}
