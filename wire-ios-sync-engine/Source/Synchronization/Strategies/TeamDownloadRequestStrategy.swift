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

struct TeamListPayload: Decodable {
    let hasMore: Bool
    let teams: [TeamPayload]

    private enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case teams
    }
}

struct TeamPayload: Decodable {

    let identifier: UUID
    let name: String
    let creator: UUID
    let binding: Bool
    let icon: String
    let iconKey: String?

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name
        case creator
        case binding
        case icon
        case iconKey = "icon_key"
    }

}

extension TeamPayload {

    func createOrUpdateTeam(in managedObjectContext: NSManagedObjectContext) -> Team? {
        var created: Bool = false
        guard let team = Team.fetchOrCreate(with: identifier,
                                            create: true,
                                            in: managedObjectContext,
                                            created: &created)
        else {
            return nil
        }

        if created {
            let selfUser = ZMUser.selfUser(in: managedObjectContext)
            _ = Member.getOrCreateMember(for: selfUser, in: team, context: managedObjectContext)
        }

        updateTeam(team, in: managedObjectContext)

        return team
    }

    func updateTeam(_ team: Team, in managedObjectContext: NSManagedObjectContext) {
        team.name = name
        team.creator = ZMUser.fetchOrCreate(with: creator, domain: nil, in: managedObjectContext)
        team.pictureAssetId = icon
        team.pictureAssetKey = iconKey

        if !binding {
            managedObjectContext.delete(team)
        }
    }

}

fileprivate extension Team {

    static var predicateForObjectsNeedingToBeUpdated: NSPredicate = {
        NSPredicate(format: "%K == YES AND %K != NULL", #keyPath(Team.needsToBeUpdatedFromBackend), Team.remoteIdentifierDataKey()!)
    }()

}

/// Responsible for downloading the team which the self user belongs to during the slow sync
/// and for updating it when processing events or when manually requested.

public final class TeamDownloadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource, ZMEventConsumer, ZMSingleRequestTranscoder, ZMDownstreamTranscoder {

    private (set) var downstreamSync: ZMDownstreamObjectSync!
    private (set) var slowSync: ZMSingleRequestSync!

    fileprivate unowned var syncStatus: SyncStatus

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus, syncStatus: SyncStatus) {
        self.syncStatus = syncStatus
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = [.allowsRequestsWhileOnline, .allowsRequestsDuringSlowSync]
        downstreamSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: Team.entityName(),
            predicateForObjectsToDownload: Team.predicateForObjectsNeedingToBeUpdated,
            filter: nil,
            managedObjectContext: managedObjectContext
        )
        slowSync = ZMSingleRequestSync(singleRequestTranscoder: self,
                                       groupQueue: managedObjectContext)
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if isSyncing {
            slowSync.readyForNextRequestIfNotBusy()
            return slowSync.nextRequest(for: apiVersion)
        } else {
            return downstreamSync.nextRequest(for: apiVersion)
        }
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [downstreamSync]
    }

    fileprivate var expectedSyncPhase: SyncPhase {
        return .fetchingTeams
    }

    fileprivate var isSyncing: Bool {
        return syncStatus.currentSyncPhase == expectedSyncPhase
    }

    // MARK: - ZMEventConsumer
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        events.forEach(process)
    }

    private func process(_ event: ZMUpdateEvent) {
        switch event.type {
        case .teamCreate: createTeam(with: event)
        case .teamDelete: deleteTeam(with: event)
        case .teamUpdate: updateTeam(with: event)
        case .teamMemberJoin: processAddedMember(with: event)
        case .teamMemberLeave: processRemovedMember(with: event)
        case .teamMemberUpdate: processUpdatedMember(with: event)
        default: break
        }
    }

    private func createTeam(with event: ZMUpdateEvent) {
        // With the new multi-account model this event should not be sent anymore,
        // and if it is we should not act on it.
        // An account will either have a team since registration or not,
        // currently there is no way to get added to a team after registering.
    }

    private func deleteTeam(with event: ZMUpdateEvent) {
        deleteAccount()
    }

    private func updateTeam(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let existingTeam = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }

        TeamUpdateEventPayload(data)?.updateTeam(existingTeam, in: managedObjectContext)
    }

    private func processAddedMember(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        guard let addedUserId = (data[TeamEventPayloadKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        let user = ZMUser.fetchOrCreate(with: addedUserId, domain: nil, in: managedObjectContext)
        user.needsToBeUpdatedFromBackend = true
        _ = Member.getOrCreateMember(for: user, in: team, context: managedObjectContext)
    }

    private func processRemovedMember(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        guard let removedUserId = (data[TeamEventPayloadKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        guard let user = ZMUser.fetch(with: removedUserId, in: managedObjectContext) else { return }
        if let member = user.membership {
            if user.isSelfUser {
                deleteAccount()
            } else {
                user.markAccountAsDeleted(at: event.timestamp ?? Date())
            }
            managedObjectContext.delete(member)
        } else {
            log.error("Trying to delete non existent membership of \(user) in \(team)")
        }
    }

    private func processUpdatedMember(with event: ZMUpdateEvent) {
        guard nil != event.teamId, let data = event.dataPayload else { return }
        guard let userId = (data[TeamEventPayloadKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        guard let member = Member.fetch(with: userId, in: managedObjectContext) else { return }
        member.needsToBeUpdatedFromBackend = true
    }

    private func deleteTeamAndConversations(_ team: Team) {
        team.conversations.forEach(managedObjectContext.delete)
        managedObjectContext.delete(team)
    }

    private func deleteAccount() {
        let notification = AccountDeletedNotification(context: managedObjectContext)
        notification.post(in: managedObjectContext.notificationContext)
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        return TeamDownloadRequestFactory.getTeamsRequest(apiVersion: apiVersion)
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard
            let rawData = response.rawData,
            let teamListPayload = TeamListPayload(rawData)
        else {
            syncStatus.failCurrentSyncPhase(phase: expectedSyncPhase)
            return
        }

        _ = teamListPayload.teams.first?.createOrUpdateTeam(in: managedObjectContext)

        syncStatus.finishCurrentSyncPhase(phase: expectedSyncPhase)
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!, apiVersion: APIVersion) -> ZMTransportRequest! {
        guard downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync, let team = object as? Team else { fatal("Wrong sync or object for: \(object.safeForLoggingDescription)") }
        return team.remoteIdentifier.map { TeamDownloadRequestFactory.getRequest(for: [$0], apiVersion: apiVersion) }
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard
            downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
            let team = object as? Team,
            let rawData = response.rawData,
            let teamPayload = TeamPayload(rawData) else { return }

        teamPayload.updateTeam(team, in: managedObjectContext)

        team.needsToBeUpdatedFromBackend = false
        team.needsToDownloadRoles = true
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync, let team = object as? Team else { return }

        managedObjectContext.delete(team)
    }
}

// MARK: - Event

fileprivate extension ZMUpdateEvent {

    var teamId: UUID? {
        return(payload[TeamEventPayloadKey.team.rawValue] as? String).flatMap(UUID.init)
    }

    var dataPayload: [String: Any]? {
        return payload[TeamEventPayloadKey.data.rawValue] as? [String: Any]
    }
}

private  enum TeamEventPayloadKey: String {

    case team
    case data
    case user
    case conversation = "conv"

}

struct TeamUpdateEventPayload: Decodable {

    let name: String?
    let icon: String?
    let iconKey: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case icon
        case iconKey = "icon_key"
    }

}

extension TeamUpdateEventPayload {

    func updateTeam(_ team: Team, in managedObjectContext: NSManagedObjectContext) {
        team.name = name
        team.pictureAssetId = icon
        team.pictureAssetKey = iconKey
    }

}

private let log = ZMSLog(tag: "Teams")
