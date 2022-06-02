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

@objc public final class MockTeam: NSManagedObject, EntityNamedProtocol {
    @NSManaged public var conversations: Set<MockConversation>?
    @NSManaged public var members: Set<MockMember>
    @NSManaged public var roles: Set<MockRole>
    @NSManaged public var creator: MockUser?
    @NSManaged public var name: String?
    @NSManaged public var pictureAssetKey: String?
    @NSManaged public var pictureAssetId: String
    @NSManaged public var identifier: String
    @NSManaged public var createdAt: Date
    @NSManaged public var isBound: Bool
    @NSManaged public var hasLegalHoldService: Bool

    public static var entityName = "Team"
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = NSUUID.create().transportString()
        createdAt = Date()
    }
}

extension MockTeam {
    public static func predicateWithIdentifier(identifier: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MockTeam.identifier), identifier)
    }
    
    @objc(containsUser:)
    public func contains(user: MockUser) -> Bool {
        guard let userMemberships = user.memberships, !userMemberships.isEmpty else { return false }
        return !userMemberships.union(members).isEmpty
    }
    
    @objc
    public static func insert(in context: NSManagedObjectContext, name: String?, assetId: String?, assetKey: String?, isBound: Bool) -> MockTeam {
        let team: MockTeam = insert(in: context)
        team.name = name
        team.pictureAssetId = assetId ?? ""
        team.pictureAssetKey = assetKey
        team.isBound = isBound
        team.roles = Set(
            [
                MockRole.insert(in: context, name: MockConversation.admin, actions: createAdminActions(context: context)),
                MockRole.insert(in: context, name: MockConversation.member, actions: createMemberActions(context: context))
            ])
        return team
    }
    
    var payloadValues: [String : Any?] {
        return [
            "id": identifier,
            "name" : name,
            "icon_key" : pictureAssetKey,
            "icon" : pictureAssetId,
            "creator" : creator?.identifier,
            "binding" : isBound
        ]
    }
    
    var payload: ZMTransportData {
        return payloadValues as NSDictionary
    }
    
    @objc
    public static func createAdminActions(context: NSManagedObjectContext) -> Set<MockAction> {
        
        return  Set(["add_conversation_member",
                 "remove_conversation_member",
                 "modify_conversation_name",
                 "modify_conversation_message_timer",
                 "modify_conversation_receipt_mode",
                 "modify_conversation_access",
                 "modify_other_conversation_member",
                 "leave_conversation",
                 "delete_conversation"].map{MockAction.insert(in: context, name: $0)})
    }
    
    @objc
    public static func createMemberActions(context: NSManagedObjectContext) -> Set<MockAction> {
        
        return  Set(["leave_conversation"].map{MockAction.insert(in: context, name: $0)})
    }
}
