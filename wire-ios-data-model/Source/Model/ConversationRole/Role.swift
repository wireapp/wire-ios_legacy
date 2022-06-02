//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

public enum TeamOrConversation {
    case team(Team)
    case conversation(ZMConversation)

    /// Creates a team if the conversation belongs to a team, or a conversation otherwise
    public static func matching(_ conversation: ZMConversation) -> TeamOrConversation {
        return self.fromTeamOrConversation(team: conversation.team, conversation: conversation)
    }

    /// Creates a team or a conversation
    static func fromTeamOrConversation(team: Team?,
                                       conversation: ZMConversation?) -> TeamOrConversation {
        if let team = team {
            return .team(team)

        } else if let conversation = conversation {
            return .conversation(conversation)
        }
        fatal("No team and no conversation")
    }
}

@objcMembers
public final class Role: ZMManagedObject {
    public static let nameKey = #keyPath(Role.name)
    public static let teamKey = #keyPath(Role.team)
    public static let conversationKey = #keyPath(Role.conversation)
    public static let actionsKey = #keyPath(Role.actions)
    public static let participantRolesKey = #keyPath(Role.participantRoles)

    @NSManaged public var name: String?

    @NSManaged public var actions: Set<Action>
    @NSManaged public var participantRoles: Set<ParticipantRole>
    @NSManaged public var team: Team?
    @NSManaged public var conversation: ZMConversation?

    public override static func entityName() -> String {
        return String(describing: Role.self)
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }

    @discardableResult
    static public func create(managedObjectContext: NSManagedObjectContext,
                              name: String,
                              conversation: ZMConversation) -> Role {
        return create(managedObjectContext: managedObjectContext,
                      name: name,
                      teamOrConversation: .conversation(conversation))
    }

    @discardableResult
    static public func create(managedObjectContext: NSManagedObjectContext,
                              name: String,
                              team: Team) -> Role {
        return create(managedObjectContext: managedObjectContext,
                      name: name,
                      teamOrConversation: .team(team))
    }

    static public func create(managedObjectContext: NSManagedObjectContext,
                              name: String,
                              teamOrConversation: TeamOrConversation) -> Role {

        let entry = Role.insertNewObject(in: managedObjectContext)
        entry.name = name
        switch teamOrConversation {
        case .team(let team):
            entry.team = team
        case .conversation(let conversation):
            entry.conversation = conversation
        }
        return entry
    }

    static func fetchExistingRole(with name: String,
                                  teamOrConversation: TeamOrConversation,
                                  in context: NSManagedObjectContext) -> Role? {
        let fetchRequest = NSFetchRequest<Role>(entityName: Role.entityName())
        let namePredicate = NSPredicate(format: "%K == %@", Role.nameKey, name)
        let teamOrConvoPredicate: NSPredicate
        switch teamOrConversation {
        case .team(let team):
            teamOrConvoPredicate = NSPredicate(format: "%K == %@", Role.teamKey, team)
        case .conversation(let convo):
            teamOrConvoPredicate = NSPredicate(format: "%K == %@", Role.conversationKey, convo)
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            namePredicate,
            teamOrConvoPredicate
        ])
        fetchRequest.fetchLimit = 1

        return context.fetchOrAssert(request: fetchRequest).first
    }

    public static func fetchOrCreateRole(with name: String,
                                         teamOrConversation: TeamOrConversation,
                                         in context: NSManagedObjectContext) -> Role {
        let existingRole = self.fetchExistingRole(with: name,
                                                  teamOrConversation: teamOrConversation,
                                                  in: context)
        return existingRole ?? create(managedObjectContext: context, name: name, teamOrConversation: teamOrConversation)
    }

    @discardableResult
    public static func createOrUpdate(with payload: [String: Any],
                                      teamOrConversation: TeamOrConversation,
                                      context: NSManagedObjectContext) -> Role? {
        guard let conversationRole = payload["conversation_role"] as? String,
              let actionNames = payload["actions"] as? [String]
        else { return nil }

        let fetchedRole = fetchExistingRole(with: conversationRole,
                                            teamOrConversation: teamOrConversation,
                                            in: context)

        let role = fetchedRole ?? Role.insertNewObject(in: context)

        actionNames.forEach { actionName in
            var created = false
            Action.fetchOrCreate(with: actionName, role: role, in: context, created: &created)
        }

        switch teamOrConversation {
        case .team(let team):
            role.team = team
        case .conversation(let conversation):
            role.conversation = conversation
        }
        role.name = conversationRole

        return role
    }
}
