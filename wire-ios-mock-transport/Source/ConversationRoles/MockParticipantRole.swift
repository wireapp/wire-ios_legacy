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
import CoreData

@objc public final class MockParticipantRole: NSManagedObject, EntityNamedProtocol {
    @NSManaged public var conversation: MockConversation
    @NSManaged public var user: MockUser
    @NSManaged public var role: MockRole?
    
    public static var entityName = "ParticipantRole"
}

extension MockParticipantRole {
    @objc
    public static func insert(in context: NSManagedObjectContext, conversation: MockConversation, user: MockUser) -> MockParticipantRole {
        let participantRole: MockParticipantRole = insert(in: context)
        participantRole.conversation = conversation
        participantRole.user = user
        
        return participantRole
    }
}
