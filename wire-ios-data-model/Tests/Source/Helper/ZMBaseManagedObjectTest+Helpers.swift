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

extension ZMBaseManagedObjectTest {

    @discardableResult
    func createConversation(in moc: NSManagedObjectContext, with participants: [ZMUser] = [], role: Role? = nil) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        conversation.addParticipantsAndUpdateConversationState(users: Set(participants), role: role)
        return conversation
    }

    func createTeam(in moc: NSManagedObjectContext) -> Team {
        let team = Team.insertNewObject(in: moc)
        team.remoteIdentifier = UUID()
        return team
    }

    func createUser(in moc: NSManagedObjectContext) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.remoteIdentifier = UUID()
        return user
    }

    @discardableResult func createMembership(in moc: NSManagedObjectContext, user: ZMUser, team: Team?, with permissions: Permissions? = nil) -> Member {
        let member = Member.insertNewObject(in: moc)
        member.user = user
        if let team = team {
            member.team = team
            member.user?.teamIdentifier = team.remoteIdentifier
        }
        if let permissions = permissions {
            member.permissions = permissions
        }
        return member
    }

    @discardableResult func createTeamMember(in moc: NSManagedObjectContext, for team: Team) -> ZMUser {
        let user = createUser(in: moc)
        createMembership(in: moc, user: user, team: team)
        return user
    }

    func createService(in moc: NSManagedObjectContext, named: String) -> ServiceUser {
        let serviceUser = createUser(in: moc)
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        serviceUser.name = named
        return serviceUser
    }

    func createExternal(in moc: NSManagedObjectContext) -> ZMUser {
        let externalUser = createUser(in: moc)
        createMembership(in: moc, user: externalUser, team: nil, with: .partner)
        return externalUser
    }
}
