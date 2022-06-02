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

public extension NSNotification.Name {
    static let teamDidRequestAsset = Notification.Name("TeamDidRequestAsset")
}

public protocol TeamType: AnyObject {

    var conversations: Set<ZMConversation> { get }
    var name: String? { get }
    var pictureAssetId: String? { get }
    var pictureAssetKey: String? { get }
    var remoteIdentifier: UUID? { get }
    var imageData: Data? { get set }

    func requestImage()
    func refreshMetadata()
}

@objcMembers
public class Team: ZMManagedObject, TeamType {

    @NSManaged public var conversations: Set<ZMConversation>
    @NSManaged public var members: Set<Member>
    @NSManaged public var roles: Set<Role>
    @NSManaged public var name: String?
    @NSManaged public var pictureAssetId: String?
    @NSManaged public var pictureAssetKey: String?
    @NSManaged public var creator: ZMUser?

    @NSManaged public var needsToRedownloadMembers: Bool
    @NSManaged public var needsToDownloadRoles: Bool

    @NSManaged private var remoteIdentifier_data: Data?

    public var remoteIdentifier: UUID? {
        get {
            guard let data = remoteIdentifier_data else { return nil }
            return UUID(data: data)
        }
        set {
            remoteIdentifier_data = newValue?.uuidData
        }
    }

    public override static func entityName() -> String {
        return "Team"
    }

    override public static func sortKey() -> String {
        return #keyPath(Team.name)
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }

    @objc(fetchOrCreateTeamWithRemoteIdentifier:createIfNeeded:inContext:created:)
    public static func fetchOrCreate(with identifier: UUID, create: Bool, in context: NSManagedObjectContext, created: UnsafeMutablePointer<Bool>?) -> Team? {
        precondition(!create || context.zm_isSyncContext, "Needs to be called on the sync context")
        if let existing = Team.fetch(with: identifier, in: context) {
            created?.pointee = false
            return existing
        } else if create {
            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = identifier
            created?.pointee = true
            return team
        }

        return nil
    }

    public func refreshMetadata() {
        needsToBeUpdatedFromBackend = true
    }
}

extension Team {

    public func members(matchingQuery query: String) -> [Member] {
        let searchPredicate = ZMUser.predicateForAllUsers(withSearch: query)

        return members.filter({ member in
            guard let user = member.user else { return false }
            return !user.isSelfUser && searchPredicate.evaluate(with: user)
        }).sorted(by: { (first, second) -> Bool in
            return first.user?.normalizedName < second.user?.normalizedName
        })
    }
}

// MARK: - Logo Image
extension Team {
    static let defaultLogoFormat = ZMImageFormat.medium

    @objc static let pictureAssetIdKey = #keyPath(Team.pictureAssetId)

    public var imageData: Data? {
        get {
            return managedObjectContext?.zm_fileAssetCache.assetData(for: self, format: Team.defaultLogoFormat, encrypted: false)
        }

        set {
            defer {
                if let uiContext = managedObjectContext?.zm_userInterface {
                    // Notify about a non core data change since the image is persisted in the file cache
                    NotificationDispatcher.notifyNonCoreDataChanges(objectID: objectID, changedKeys: [#keyPath(Team.imageData)], uiContext: uiContext)
                }
            }

            guard let newValue = newValue else {
                managedObjectContext?.zm_fileAssetCache.deleteAssetData(for: self, format: Team.defaultLogoFormat, encrypted: false)
                return
            }

            managedObjectContext?.zm_fileAssetCache.storeAssetData(for: self, format: Team.defaultLogoFormat, encrypted: false, data: newValue)
        }
    }

    public func requestImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_fileAssetCache.hasDataOnDisk(for: self, format: Team.defaultLogoFormat, encrypted: false) else { return }

        NotificationInContext(name: .teamDidRequestAsset,
                              context: moc.notificationContext,
                              object: objectID).post()
    }

    public static var imageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", Team.pictureAssetIdKey)
        let notCached = NSPredicate { (team, _) -> Bool in
            guard let team = team as? Team else { return false }
            return team.imageData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, notCached])
    }

}
