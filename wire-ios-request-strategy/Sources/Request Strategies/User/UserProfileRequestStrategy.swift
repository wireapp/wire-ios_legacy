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

/// Request strategy for fetching user profiles and processing user update events.
///
/// User profiles are fetched:
/// - During the `.fetchingUsers` slow sync phase.
/// - When a user is marked as `needsToBeUpdatedFromBackend`.
///
public class UserProfileRequestStrategy: AbstractRequestStrategy, IdentifierObjectSyncDelegate {

    var isFetchingAllConnectedUsers: Bool = false
    let syncProgress: SyncProgress

    let userProfileByID: IdentifierObjectSync<UserProfileByIDTranscoder>
    let userProfileByQualifiedID: IdentifierObjectSync<UserProfileByQualifiedIDTranscoder>

    let userProfileByIDTranscoder: UserProfileByIDTranscoder
    let userProfileByQualifiedIDTranscoder: UserProfileByQualifiedIDTranscoder

    public init(managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                syncProgress: SyncProgress) {

        self.syncProgress = syncProgress
        self.userProfileByIDTranscoder = UserProfileByIDTranscoder(context: managedObjectContext)
        self.userProfileByQualifiedIDTranscoder = UserProfileByQualifiedIDTranscoder(context: managedObjectContext)

        self.userProfileByID = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                    transcoder: userProfileByIDTranscoder)
        self.userProfileByQualifiedID = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                             transcoder: userProfileByQualifiedIDTranscoder)

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [.allowsRequestsWhileOnline,
                              .allowsRequestsDuringSlowSync]
        self.userProfileByID.delegate = self
        self.userProfileByQualifiedID.delegate = self
        self.userProfileByQualifiedIDTranscoder.contextChangedTracker = self
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        fetchAllConnectedUsers(for: apiVersion)
        return userProfileByQualifiedID.nextRequest(for: apiVersion) ?? userProfileByID.nextRequest(for: apiVersion)
    }

    func fetchAllConnectedUsers(for apiVersion: APIVersion) {
        guard
            syncProgress.currentSyncPhase == .fetchingUsers,
            !isFetchingAllConnectedUsers
        else {
            return
        }

        let allConnectedUsers = self.allConnectedUsers()

        if allConnectedUsers.isEmpty {
            syncProgress.finishCurrentSyncPhase(phase: .fetchingUsers)
        } else {
            fetch(users: allConnectedUsers, for: apiVersion)
        }

        isFetchingAllConnectedUsers = true
    }

    func allConnectedUsers() -> Set<ZMUser> {
        let fetchRequest = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
        let connections = managedObjectContext.fetchOrAssert(request: fetchRequest)
        return Set(connections.compactMap(\.to))
    }

    func fetch(users: Set<ZMUser>, for apiVersion: APIVersion) {
        let users = users.filter { !$0.isSelfUser }
        guard !users.isEmpty else { return }

        switch apiVersion {
        case .v0:
            userProfileByID.sync(identifiers: users.compactMap(\.remoteIdentifier))

        case .v1:
            if let qualifiedUserIDs = users.qualifiedUserIDs {
                userProfileByQualifiedID.sync(identifiers: qualifiedUserIDs)
            } else if let domain = APIVersion.domain {
                let qualifiedUserIDs = users.fallbackQualifiedIDs(localDomain: domain)
                userProfileByQualifiedID.sync(identifiers: qualifiedUserIDs)
            }
        }
    }

    public func didFailToSyncAllObjects() {
        if syncProgress.currentSyncPhase == .fetchingUsers {
            syncProgress.failCurrentSyncPhase(phase: .fetchingUsers)
            isFetchingAllConnectedUsers = false
        }
    }

    public func didFinishSyncingAllObjects() {
        guard
            syncProgress.currentSyncPhase == .fetchingUsers,
            !userProfileByID.isSyncing,
            !userProfileByQualifiedID.isSyncing
        else {
            return
        }

        syncProgress.finishCurrentSyncPhase(phase: .fetchingUsers)
        isFetchingAllConnectedUsers = false
    }

}

extension UserProfileRequestStrategy: ZMContextChangeTracker {

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        guard let apiVersion = APIVersion.current else { return }

        let usersNeedingToBeUpdated = objects
            .compactMap { $0 as? ZMUser}
            .filter(\.needsToBeUpdatedFromBackend)

        fetch(users: Set(usersNeedingToBeUpdated), for: apiVersion)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return ZMUser.sortedFetchRequest(with: ZMUser.predicateForNeedingToBeUpdatedFromBackend()!)
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        guard
            let users = objects as? Set<ZMUser>,
            let apiVersion = APIVersion.current
        else {
            return
        }

        fetch(users: users, for: apiVersion)
    }

}

extension UserProfileRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            switch event.type {
            case .userUpdate:
                processUserUpdate(event)
            case .userDelete:
                processUserDeletion(event)
            default:
                break
            }
        }
    }

    func processUserUpdate(_ updateEvent: ZMUpdateEvent) {
        guard updateEvent.type == .userUpdate else { return }

        guard
            let payloadAsDictionary = updateEvent.payload["user"] as? [String: Any],
            let payloadData = try? JSONSerialization.data(withJSONObject: payloadAsDictionary, options: []),
            let userProfile = Payload.UserProfile(payloadData),
            let userID = userProfile.id
        else {
            return Logging.eventProcessing.error("Malformed user.update update event, skipping...")
        }

        let user = ZMUser.fetchOrCreate(with: userID,
                                        domain: userProfile.qualifiedID?.domain,
                                        in: managedObjectContext)
        userProfile.updateUserProfile(for: user, authoritative: false)
    }

    func processUserDeletion(_ updateEvent: ZMUpdateEvent) {
        guard updateEvent.type == .userDelete else { return }

        guard let userId = (updateEvent.payload["id"] as? String).flatMap(UUID.init),
              let user = ZMUser.fetch(with: userId, in: managedObjectContext)
        else {
            return Logging.eventProcessing.error("Malformed user.delete update event, skipping...")
        }

        if user.isSelfUser {
            deleteAccount()
        } else {
            user.markAccountAsDeleted(at: updateEvent.timestamp ?? Date())
        }
    }

    private func deleteAccount() {
        let notification = AccountDeletedNotification(context: managedObjectContext)
        notification.post(in: managedObjectContext.notificationContext)
    }

}

class UserProfileByIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = UUID

    var fetchLimit: Int =  1600 / 25 // UUID as string is 24 + 1 for the comma

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        // GET /users?ids=?
        let userIDs = identifiers.map({ $0.transportString() }).joined(separator: ",")
        return ZMTransportRequest(getFromPath: "/users?ids=\(userIDs)", apiVersion: apiVersion.rawValue)
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>) {

        if response.httpStatus == 404, let responseFailure = Payload.ResponseFailure(response, decoder: decoder) {
            if case .notFound = responseFailure.label {
                markUserProfilesAsFetched(identifiers)
                return
            }
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.UserProfiles(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateUserProfiles(in: context)

        let missingIdentifiers = identifiers.subtracting(payload.compactMap(\.id))
        markUserProfilesAsFetched(missingIdentifiers)
    }

    private func markUserProfilesAsFetched(_ missingUsers: Set<UUID>) {
        for userID in missingUsers {
            let user = ZMUser.fetch(with: userID, in: context)
            user?.needsToBeUpdatedFromBackend = false
        }
    }

}

class UserProfileByQualifiedIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = QualifiedID

    var fetchLimit: Int = 500

    weak var contextChangedTracker: ZMContextChangeTracker?
    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            apiVersion > .v0,
            let payloadData = Payload.QualifiedUserIDList(qualifiedIDs: Array(identifiers)).payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        // POST /list-users
        let path = NSString.path(withComponents: ["/list-users"])
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payloadAsString as ZMTransportData?, apiVersion: apiVersion.rawValue)
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<QualifiedID>) {
        if response.httpStatus == 404, let responseFailure = Payload.ResponseFailure(response, decoder: decoder) {
            guard case .notFound = responseFailure.label else { return }
            markUserProfilesAsFetched(identifiers)
            return
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.UserProfiles(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateUserProfiles(in: context)

        let missingIdentifiers = identifiers.subtracting(payload.compactMap(\.qualifiedID))
        markUserProfilesAsFetched(missingIdentifiers)
    }

    private func markUserProfilesAsFetched(_ missingUsers: Set<QualifiedID>) {
        for qualifiedID in missingUsers {
            let user = ZMUser.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            user?.needsToBeUpdatedFromBackend = false
        }
    }

}

private extension Collection where Element == ZMUser {

    func fallbackQualifiedIDs(localDomain: String) -> [QualifiedID] {
        return compactMap { user in
            if let qualifiedID = user.qualifiedID {
                return qualifiedID
            } else if let identifier = user.remoteIdentifier {
                return QualifiedID(uuid: identifier, domain: localDomain)
            } else {
                return nil
            }
        }
    }

}
