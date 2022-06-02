//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

/// Defines how users can join a conversation.
public struct ConversationAccessMode: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    /// Allowed user can be added by an existing conv member.
    public static let invite    = ConversationAccessMode(rawValue: 1 << 0)
    /// Allowed user can join the conversation using the code.
    public static let code      = ConversationAccessMode(rawValue: 1 << 1)
    /// Allowed user can join knowing only the conversation ID.
    public static let link      = ConversationAccessMode(rawValue: 1 << 2)
    /// Internal value that indicates the conversation that cannot be joined (1-1).
    public static let `private` = ConversationAccessMode(rawValue: 1 << 3)

    public static let legacy    = invite
    public static let teamOnly  = ConversationAccessMode()
    public static let allowGuests: ConversationAccessMode = [.invite, .code]
}

extension ConversationAccessMode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }

}

public extension ConversationAccessMode {
    internal static let stringValues: [ConversationAccessMode: String] = [.invite: "invite",
                                                                          .code: "code",
                                                                          .link: "link",
                                                                          .`private`: "private"]

    var stringValue: [String] {
        return ConversationAccessMode.stringValues.compactMap { self.contains($0) ? $1 : nil }
    }

    init(values: [String]) {
        var result = ConversationAccessMode()
        ConversationAccessMode.stringValues.forEach {
            if values.contains($1) {
                result.formUnion($0)
            }
        }
        self = result
    }
}

public extension ConversationAccessMode {
    static func value(forAllowGuests allowGuests: Bool) -> ConversationAccessMode {
        return allowGuests ? .allowGuests : .teamOnly
    }
}

/// Defines who can join the conversation.
public enum ConversationAccessRole: String {
    /// Only the team member can join.
    case team = "team"
    /// Only users who have verified their phone number / email can join.
    case activated = "activated"
    /// Any user can join.
    case nonActivated = "non_activated"
    // 1:1 conversation
    case `private` = "private"

    public static func fromAccessRoleV2(_ accessRoles: Set<ConversationAccessRoleV2>) -> ConversationAccessRole {
        if accessRoles.contains(.guest) {
          return .nonActivated
        } else if accessRoles.contains(.nonTeamMember) || accessRoles.contains(.service) {
          return .activated
        } else if accessRoles.contains(.teamMember) {
          return .team
        } else {
          return .private
        }
    }

}

/// The issue:
///
/// The access_role specifies who can be in the conversation. When “guests and services” is allowed,
/// then the value is non_activated (indicating the anyone can be in the conversation).
/// When “guests and services” is not allowed, then the value is team, indicating that only team member can be in the conversation.
/// These values do not distinguish between human guests and non-human services.
/// For this reason, the access_role property will be deprecated and a new access role property should be used.
///
/// The fix:
///
/// The new access role property access_role_v2 will contain a set of values,
/// each of which is used to distinguish a type of user, that describes who can be a participant of the conversation.
///

public enum ConversationAccessRoleV2: String {
    /// Users with Wire accounts belonging to the same team owning the conversation.
    case teamMember = "team_member"
    /// Users with Wire accounts belonging to another team or no team.
    case nonTeamMember = "non_team_member"
    /// Users without Wire accounts, or wireless users (i.e users who join with a guest link and temporary account).
    case guest = "guest"
    /// A service pseudo-user, aka a non-human bot.
    case service = "service"

    public static func fromLegacyAccessRole(_ accessRole: ConversationAccessRole) -> Set<Self> {
        switch accessRole {
        case .team:
            return [.teamMember]
        case .activated:
            return [.teamMember, .nonTeamMember, guest]
        case .nonActivated:
            return [.teamMember, .nonTeamMember, guest, .service]
        case .private:
            return []
        }
    }
}

public extension ConversationAccessRole {
    static func value(forAllowGuests allowGuests: Bool) -> ConversationAccessRole {
        return allowGuests ? ConversationAccessRole.nonActivated : ConversationAccessRole.team
    }
}

extension ZMConversation: SwiftConversationLike {
    @NSManaged dynamic internal var accessModeStrings: [String]?
    @NSManaged dynamic internal var accessRoleString: String?
    @NSManaged dynamic internal var accessRoleStringsV2: [String]?

    public var sortedActiveParticipantsUserTypes: [UserType] {
        return sortedActiveParticipants
    }

    public var teamType: TeamType? {
        return team
    }

    public internal(set) var accessRoles: Set<ConversationAccessRoleV2> {
        get {
            guard let strings = accessRoleStringsV2 else { return [.teamMember] }
            return Set(strings.compactMap(ConversationAccessRoleV2.init))
        }
        set {
            accessRoleStringsV2 = newValue.map(\.rawValue)
        }
    }

    /// If set to false, only team member can join the conversation.
    /// True means that a regular guest OR wireless guests could join
    /// Controls the values of `accessMode` and `accessRoleV2`.
    @objc public var allowGuests: Bool {
        get {
            return accessMode != .teamOnly && accessRoles.contains(.guest) && accessRoles.contains(.nonTeamMember)
        }
        set {
            accessMode = ConversationAccessMode.value(forAllowGuests: newValue)
            if newValue {
                accessRoles.insert(.guest)
                accessRoles.insert(.nonTeamMember)
            } else {
                accessRoles.remove(.guest)
                accessRoles.remove(.nonTeamMember)
            }

        }
    }

    /// If set to false, only team member or guest can join the conversation.
    /// True means that a service could join
    /// Controls the value of `accessRoleV2`.
    @objc public var allowServices: Bool {
        get {
            return accessRoles.contains(.service)
        }
        set {
            if newValue {
                accessRoles.insert(.service)
            } else {
                accessRoles.remove(.service)
            }
        }

    }

    // The conversation access mode is stored as an array of string in CoreData, cf. `acccessModeStrings`.

    /// Defines how users can join a conversation.
    public var accessMode: ConversationAccessMode? {
        get {
            guard let strings = self.accessModeStrings else {
                return nil
            }

            return ConversationAccessMode(values: strings)
        }
        set {
            guard let value = newValue else {
                accessModeStrings = nil
                return
            }
            accessModeStrings = value.stringValue
        }
    }

    /// Defines who can join the conversation.
    public var accessRole: ConversationAccessRole? {
        get {
            guard let strings = self.accessRoleString else {
                return nil
            }

            return ConversationAccessRole(rawValue: strings)
        }
        set {
            guard let value = newValue else {
                accessRoleString = nil
                return
            }
            accessRoleString = value.rawValue
        }
    }
}
