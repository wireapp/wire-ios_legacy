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

import Foundation

@objc
public enum AvailabilityKind: Int, CaseIterable {
    case none, available, busy, away

    public init(proto: WireProtos.Availability) {
        /// TODO: change ZMAvailabilityType to NS_CLOSED_ENUM
        switch proto.type {
        case .none:
            self = .none
        case .available:
            self = .available
        case .away:
            self = .away
        case .busy:
            self = .busy
        }
    }

}

/// Describes how the user should be notified about a change.
public struct NotificationMethod: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Alert user by local notification
    public static let notification = NotificationMethod(rawValue: 1 << 0)
    /// Alert user by alert dialogue
    public static let alert = NotificationMethod(rawValue: 1 << 1)

    public static let all: NotificationMethod = [.notification, .alert]

}

extension ZMUser {

    /// The set of all users to receive an availability status broadcast message.
    ///
    /// Broadcast messages are expensive for large teams. Therefore it is necessary broadcast to
    /// a limited subset of all users. Known team members are priortized first, followed by
    /// connected non team members. The self user is guaranteed to be a recipient.
    ///
    /// - Parameters:
    ///     - context: The context to search in.
    ///     - maxCount: The maximum number of recipients to return.

    public static func recipientsForAvailabilityStatusBroadcast(in context: NSManagedObjectContext, maxCount: Int) -> Set<ZMUser> {
        var recipients: Set = [selfUser(in: context)]
        var remainingSlots = maxCount - recipients.count

        let sortByIdentifer: (ZMUser, ZMUser) -> Bool = {
            $0.remoteIdentifier.transportString() < $1.remoteIdentifier.transportString()
        }

        let teamMembers = knownTeamMembers(in: context)
            .sorted(by: sortByIdentifer)
            .prefix(remainingSlots)

        recipients.formUnion(teamMembers)
        remainingSlots = maxCount - recipients.count

        guard remainingSlots > 0 else { return recipients }

        let teamUsers = knownTeamUsers(in: context)
            .sorted(by: sortByIdentifer)
            .prefix(remainingSlots)

        recipients.formUnion(teamUsers)

        recipients = recipients.filter { !$0.isFederated }

        return recipients
    }

    /// The set of all users who both share the team and a conversation with the self user.
    ///
    /// Note: the self user is not included.

    static func knownTeamMembers(in context: NSManagedObjectContext) -> Set<ZMUser> {
        let selfUser = ZMUser.selfUser(in: context)

        guard selfUser.hasTeam else { return Set() }

        let teamMembersInConversationWithSelfUser = selfUser.conversations.lazy
            .flatMap { $0.participantRoles }
            .compactMap { $0.user }
            .filter { $0.isOnSameTeam(otherUser: selfUser) && !$0.isSelfUser }

        return Set(teamMembersInConversationWithSelfUser)
    }

    /// The set of all users from another team who are connected with the self user.

    static func knownTeamUsers(in context: NSManagedObjectContext) -> Set<ZMUser> {
        let connectedPredicate = ZMUser.predicateForUsers(withConnectionStatuses: [ZMConnectionStatus.accepted.rawValue])
        let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        request.predicate = connectedPredicate

        let connections = Set(context.fetchOrAssert(request: request))
        let selfUser = ZMUser.selfUser(in: context)
        let result = connections.filter { $0.hasTeam && !$0.isOnSameTeam(otherUser: selfUser) }
        return Set(result)
    }

    @objc public var availability: AvailabilityKind {
        get {
            self.willAccessValue(forKey: AvailabilityKey)
            let value = (self.primitiveValue(forKey: AvailabilityKey) as? NSNumber) ?? NSNumber(value: 0)
            self.didAccessValue(forKey: AvailabilityKey)

            return AvailabilityKind(rawValue: value.intValue) ?? .none
        }

        set {
            guard isSelfUser else { return } // TODO move this setter to ZMEditableUser

            updateAvailability(newValue)
        }
    }

    internal func updateAvailability(_ newValue: AvailabilityKind) {
        self.willChangeValue(forKey: AvailabilityKey)
        self.setPrimitiveValue(NSNumber(value: newValue.rawValue), forKey: AvailabilityKey)
        self.didChangeValue(forKey: AvailabilityKey)
    }

    public func updateAvailability(from genericMessage: GenericMessage) {
        updateAvailability(AvailabilityKind(proto: genericMessage.availability))
    }

    private static let needsToNotifyAvailabilityBehaviourChangeKey = "needsToNotifyAvailabilityBehaviourChange"

    /// Returns an option set describing how we should notify the user about the change in behaviour for the availability feature
    public var needsToNotifyAvailabilityBehaviourChange: NotificationMethod {
        get {
            guard let rawValue = managedObjectContext?.persistentStoreMetadata(forKey: type(of: self).needsToNotifyAvailabilityBehaviourChangeKey) as? Int else { return [] }

            return NotificationMethod(rawValue: rawValue)
        }
        set {
            managedObjectContext?.setPersistentStoreMetadata(newValue.rawValue, key: type(of: self).needsToNotifyAvailabilityBehaviourChangeKey)
        }
    }

}
