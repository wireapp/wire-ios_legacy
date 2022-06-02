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

import Foundation

public typealias Conversation = ConversationLike & SwiftConversationLike

@objc
public protocol ConversationLike: NSObjectProtocol {
    var conversationType: ZMConversationType { get }
    var isSelfAnActiveMember: Bool { get }
    var teamRemoteIdentifier: UUID? { get }

    func localParticipantsContain(user: UserType) -> Bool
    var localParticipantsCount: Int { get }

    var displayName: String { get }
    var connectedUserType: UserType? { get }
    var allowGuests: Bool { get }
    var allowServices: Bool { get }

    var isUnderLegalHold: Bool { get }
    var securityLevel: ZMConversationSecurityLevel { get }

    func verifyLegalHoldSubjects()

    var sortedActiveParticipantsUserTypes: [UserType] { get }

    var relatedConnectionState: ZMConnectionStatus { get }
    var lastMessage: ZMConversationMessage? { get }
    var firstUnreadMessage: ZMConversationMessage? { get }

    var areServicesPresent: Bool { get }
}

// Since ConversationLike must have @objc signature(@objc UserType has a ConversationLike property), create another protocol to abstract Swift only properties
public protocol SwiftConversationLike {
    var accessMode: ConversationAccessMode? { get }
    var accessRoles: Set<ConversationAccessRoleV2> { get }

    var teamType: TeamType? { get }

    var mutedMessageTypes: MutedMessageTypes { get set }
    var sortedOtherParticipants: [UserType] { get }
    var sortedServiceUsers: [UserType] { get }
}

extension ZMConversation: ConversationLike {
    public var localParticipantsCount: Int {
        return localParticipants.count
    }

    public func localParticipantsContain(user: UserType) -> Bool {
        guard let user = user as? ZMUser else { return false }
        return localParticipants.contains(user)
    }

    public var connectedUserType: UserType? {
        return connectedUser
	}

	private static let userNameSorter: (UserType, UserType) -> Bool = {
		$0.name < $1.name
	}

	public var sortedOtherParticipants: [UserType] {
		return localParticipants.filter { !$0.isServiceUser }.sorted(by: ZMConversation.userNameSorter)
	}

	public var sortedServiceUsers: [UserType] {
		return localParticipants.filter { $0.isServiceUser }.sorted(by: ZMConversation.userNameSorter)
    }
}
