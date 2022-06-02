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

extension ZMConversation {
    public class func existingConversation(in moc: NSManagedObjectContext, service: ServiceUser, team: Team?) -> ZMConversation? {
        guard let team = team else { return nil }
        guard let serviceID = service.serviceIdentifier else { return nil }
        let sameTeam = predicateForConversations(in: team)
        let groupConversation = NSPredicate(format: "%K == %d", ZMConversationConversationTypeKey, ZMConversationType.group.rawValue)
        let selfIsActiveMember = NSPredicate(format: "ANY %K.user == %@", ZMConversationParticipantRolesKey, ZMUser.selfUser(in: moc))
        let onlyOneOtherParticipant = NSPredicate(format: "%K.@count == 2", ZMConversationParticipantRolesKey)
        let hasParticipantWithServiceIdentifier = NSPredicate(format: "ANY %K.user.%K == %@", ZMConversationParticipantRolesKey, #keyPath(ZMUser.serviceIdentifier), serviceID)
        let noUserDefinedName = NSPredicate(format: "%K == nil", #keyPath(ZMConversation.userDefinedName))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sameTeam, groupConversation, selfIsActiveMember, onlyOneOtherParticipant, hasParticipantWithServiceIdentifier, noUserDefinedName])

        let fetchRequest = sortedFetchRequest(with: predicate)

        fetchRequest.fetchLimit = 1
        let result = moc.fetchOrAssert(request: fetchRequest)

        return result.first as? ZMConversation
    }
}
