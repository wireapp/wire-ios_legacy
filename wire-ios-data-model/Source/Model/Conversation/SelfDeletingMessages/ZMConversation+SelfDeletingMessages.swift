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

extension ZMConversation {

    @NSManaged var localMessageDestructionTimeout: TimeInterval
    @NSManaged var syncedMessageDestructionTimeout: TimeInterval

    /// Whether a group conversation timeout value exists.

    public var hasSyncedMessageDestructionTimeout: Bool {
        return messageDestructionTimeoutValue(for: .groupConversation) != .none
    }

    /// Whether a personal timeout value exists for the self user.

    public var hasLocalMessageDestructionTimeout: Bool {
        return messageDestructionTimeoutValue(for: .selfUser) != .none
    }

    /// The timeout value actively used with new messages.

    public var activeMessageDestructionTimeoutValue: MessageDestructionTimeoutValue? {
        guard let type = activeMessageDestructionTimeoutType else { return nil }
        return messageDestructionTimeoutValue(for: type)
    }

    /// The type of timeout used with new messages.

    public var activeMessageDestructionTimeoutType: MessageDestructionTimeoutType? {
        if hasForcedMessageDestructionTimeout {
            return .team
        } else if hasSyncedMessageDestructionTimeout {
            return .groupConversation
        } else if hasLocalMessageDestructionTimeout {
            return .selfUser
        } else {
            return nil
        }
    }

    /// The message destruction timeout value used for the given type.
    ///
    /// This is not necessarily the timeout used when appending new messages. See `activeTimeoutValue`.

    public func messageDestructionTimeoutValue(for type: MessageDestructionTimeoutType) -> MessageDestructionTimeoutValue {
        switch type {
        case .team:
            return .init(rawValue: teamMessageDestructionTimeout)
        case .groupConversation:
            return .init(rawValue: syncedMessageDestructionTimeout)
        case .selfUser:
            return .init(rawValue: localMessageDestructionTimeout)
        }
    }

    /// Set the given timeout value for the given timeout type.
    ///
    /// Note: setting a timeout for the `team` type has no effect since this is controlled by the
    /// `Feature.SelfDeletingMessages` feature config.

    public func setMessageDestructionTimeoutValue(_ value: MessageDestructionTimeoutValue, for type: MessageDestructionTimeoutType) {
        switch type {
        case .team:
            break
        case .groupConversation:
            syncedMessageDestructionTimeout = value.rawValue
        case .selfUser:
            localMessageDestructionTimeout = value.rawValue
        }
    }

    public func appendMessageTimerUpdateMessage(fromUser user: ZMUser, timer: Double, timestamp: Date) {
        appendSystemMessage(
            type: .messageTimerUpdate,
            sender: user,
            users: [user],
            clients: nil,
            timestamp: timestamp,
            messageTimer: timer
        )

        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }

        managedObjectContext?.enqueueDelayedSave()
    }

    // MARK: - Helpers

    private var hasForcedMessageDestructionTimeout: Bool {
        guard let feature = selfDeletingMessagesFeature else { return false }
        return feature.isForcedOff || feature.isForcedOn
    }

    private var teamMessageDestructionTimeout: TimeInterval {
        guard
            let feature = selfDeletingMessagesFeature,
            feature.status == .enabled
        else {
            return 0
        }

        return TimeInterval(feature.config.enforcedTimeoutSeconds)
    }

    private var selfDeletingMessagesFeature: Feature.SelfDeletingMessages? {
        guard let context = managedObjectContext else { return nil }
        return FeatureService(context: context).fetchSelfDeletingMesssages()
    }

}

private extension Feature.SelfDeletingMessages {

    var isForcedOff: Bool {
        return status == .disabled
    }

    var isForcedOn: Bool {
        return config.enforcedTimeoutSeconds > 0
    }

    var timeoutValue: MessageDestructionTimeoutValue {
        return .init(rawValue: Double(config.enforcedTimeoutSeconds))
    }

}
