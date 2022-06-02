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

@objcMembers public class Member: ZMManagedObject {

    @NSManaged public var team: Team?
    @NSManaged public var user: ZMUser?
    @NSManaged public var createdBy: ZMUser?
    @NSManaged public var createdAt: Date?
    @NSManaged public var remoteIdentifier_data: Data?
    @NSManaged private var permissionsRawValue: Int64

    public var permissions: Permissions {
        get {
            return Permissions(rawValue: permissionsRawValue)
        }
        set {
            permissionsRawValue = newValue.rawValue
        }
    }

    public override static func entityName() -> String {
        return "Member"
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }

    public override static func defaultSortDescriptors() -> [NSSortDescriptor] {
        return []
    }

    public var remoteIdentifier: UUID? {
        get {
            guard let data = remoteIdentifier_data else { return nil }
            return UUID(data: data)
        }
        set {
            remoteIdentifier_data = newValue?.uuidData
        }
    }

    @objc(getOrCreateMemberForUser:inTeam:context:)
    public static func getOrCreateMember(for user: ZMUser, in team: Team, context: NSManagedObjectContext) -> Member {
        precondition(context.zm_isSyncContext)

        if let existing = user.membership {
            return existing
        }
        else if let userId = user.remoteIdentifier, let existing = Member.fetch(with: userId, in: context) {
            return existing
        }

        let member = insertNewObject(in: context)
        member.team = team
        member.user = user
        member.remoteIdentifier = user.remoteIdentifier
        member.needsToBeUpdatedFromBackend = true
        return member
    }

}

// MARK: - Transport

private enum ResponseKey: String {
    case user, permissions, createdBy = "created_by", createdAt = "created_at"

    enum Permissions: String {
        case `self`, copy
    }
}

extension Member {

    @discardableResult
    public static func createOrUpdate(with payload: [String: Any], in team: Team, context: NSManagedObjectContext) -> Member? {
        guard let id = (payload[ResponseKey.user.rawValue] as? String).flatMap(UUID.init) else { return nil }

        let user = ZMUser.fetchOrCreate(with: id, domain: nil, in: context)
        let createdAt = (payload[ResponseKey.createdAt.rawValue] as? String).flatMap(NSDate.init(transport:)) as Date?
        let createdBy = (payload[ResponseKey.createdBy.rawValue] as? String).flatMap(UUID.init)
        let member = getOrCreateMember(for: user, in: team, context: context)

        member.updatePermissions(with: payload)
        member.createdAt = createdAt
        member.createdBy = createdBy.flatMap({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context) })

        return member
    }

    public func updatePermissions(with payload: [String: Any]) {
        guard let userID = (payload[ResponseKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        precondition(remoteIdentifier == userID, "Trying to update member with non-matching payload: \(payload), \(self)")
        guard let permissionsPayload = payload[ResponseKey.permissions.rawValue] as? [String: Any] else { return }
        guard let selfPermissions = permissionsPayload[ResponseKey.Permissions.`self`.rawValue] as? NSNumber else { return }
        permissions = Permissions(rawValue: selfPermissions.int64Value)
    }

}
