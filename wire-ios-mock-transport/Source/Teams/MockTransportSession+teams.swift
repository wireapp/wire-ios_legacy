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

extension ZMTransportResponse {

    static func teamNotFound(apiVersion: APIVersion) -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label" : "no-team"] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    static func notTeamMember(apiVersion: APIVersion) -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label" : "no-team-member"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    static func operationDenied(apiVersion: APIVersion) -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label" : "operation-denied"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    static func conversationNotFound(apiVersion: APIVersion) -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label" : "no-convo"] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

}

extension MockTransportSession {
    @objc(processTeamsRequest:)
    public func processTeamsRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        var response: ZMTransportResponse?

        guard let apiVersion = APIVersion(rawValue: request.apiVersion) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
        
        switch request {
        case "/teams":
            response = fetchAllTeams(query: request.queryParameters, apiVersion: apiVersion)
        case "/teams/*":
            response = fetchTeam(with: request.RESTComponents(index: 1), apiVersion: apiVersion)
        case "/teams/*/conversations/*" where request.method == .methodDELETE:
            response = deleteTeamConversation(teamId: request.RESTComponents(index: 1), conversationId: request.RESTComponents(index: 3), apiVersion: apiVersion)
        case "/teams/*/conversations/roles"/* where request.method == .methodGET*/:
            response = fetchRolesForTeam(with: request.RESTComponents(index: 1), apiVersion: apiVersion)
        case "/teams/*/services/whitelisted":
            response = fetchWhitelistedServicesForTeam(with: request.RESTComponents(index: 1), query: request.queryParameters, apiVersion: apiVersion)
        case "/teams/*/invitations":
            response = sendTeamInvitation(with: request.RESTComponents(index: 1), apiVersion: apiVersion)
        case "/teams/*/members":
            response = fetchMembersForTeam(with: request.RESTComponents(index: 1), apiVersion: apiVersion)
        case "/teams/*/members/*":
            response = fetchMemberForTeam(withTeamId: request.RESTComponents(index: 1), userId: request.RESTComponents(index: 3), apiVersion: apiVersion)
        case "/teams/*/get-members-by-ids-using-post" where request.method == .methodPOST:
            let payload = request.payload?.asDictionary()
            let userIDs = payload?["user_ids"] as? [String]
            response = fetchMembersForTeam(with: request.RESTComponents(index: 1), userIds: userIDs, apiVersion: apiVersion)
        case "/teams/*/legalhold/*/approve":
            response = approveUserLegalHold(inTeam: request.RESTComponents(index: 1), forUser: request.RESTComponents(index: 3), payload: request.payload, method: request.method, apiVersion: apiVersion)
        default:
            break
        }

        if let response = response {
            return response
        } else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
    }
    
    private func fetchTeam(with identifier: String?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let identifier = identifier else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: identifier)
        guard let team : MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate),
              let selfMemberships = selfUser.memberships, selfMemberships.contains(where: {$0.team == team})
        else {
            return .teamNotFound(apiVersion: apiVersion)
        }
        if let permissionError = ensurePermission([], in: team, apiVersion: apiVersion) {
            return permissionError
        }
        return ZMTransportResponse(payload: team.payload, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func fetchAllTeams(query: [String : Any], apiVersion: APIVersion) -> ZMTransportResponse? {
        let teams = selfUser.memberships?.map{$0.team} ?? []
        let payload: [String : Any] = [
            "teams" : teams.map { $0.payload },
            "has_more" : false
        ]
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func paginate(teams: [MockTeam], start: String?, size: Int?) -> ([MockTeam], Bool) {
        var startTeamIndex: Int?
        if let start = start {
            for (idx, team) in teams.enumerated() {
                if team.identifier == start {
                    if idx + 1 < teams.count {
                        startTeamIndex = idx + 1
                    } else {
                        startTeamIndex = teams.count - 1
                    }
                    break
                }
            }
            // The queried team was not found
            if startTeamIndex == nil {
                return ([], false)
            }
        }
        
        let teamsFrom = startTeamIndex ?? 0
        let teamsSize = size ?? 100
        let paginatedTeams = teams.suffix(from: teamsFrom).prefix(teamsSize)
        
        let hasMore = !paginatedTeams.isEmpty && (teams.last != paginatedTeams.last)
        return (Array(paginatedTeams), hasMore)
    }
    
    private func deleteTeamConversation(teamId: String?, conversationId: String?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let teamId = teamId, let conversationId = conversationId  else { return nil }
        
        let predicate = MockTeam.predicateWithIdentifier(identifier: teamId)
        
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else {
            return .notTeamMember(apiVersion: apiVersion)
        }

        guard let selfTeams = selfUser.memberships, !selfTeams.union(team.members).isEmpty else {
            return .notTeamMember(apiVersion: apiVersion)
        }
        
        guard let conversation = fetchConversation(with: conversationId) else {
            return .conversationNotFound(apiVersion: apiVersion)
        }
        
        managedObjectContext.delete(conversation)
        
        return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func sendTeamInvitation(with identifier: String?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let identifier = identifier else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: identifier)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound(apiVersion: apiVersion) }
        
        
        if let permissionError = ensurePermission(.addTeamMember, in: team, apiVersion: apiVersion) {
            return permissionError
        }
        
        return ZMTransportResponse(payload: nil, httpStatus: 201, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func fetchMembersForTeam(with teamId: String?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let teamId = teamId else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: teamId)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound(apiVersion: apiVersion) }
        if let permissionError = ensurePermission(.getMemberPermissions, in: team, apiVersion: apiVersion) {
            return permissionError
        }
        
        let payload: [String : Any] = [
            "members" : team.members.map { $0.payload },
            "hasMore" : false
        ]

        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func fetchMembersForTeam(with teamId: String?, userIds: [String]?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let teamId = teamId, let userIds = userIds else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: teamId)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound(apiVersion: apiVersion) }
        let members = team.members.filter({ userIds.contains($0.user.identifier) })
        if let permissionError = ensurePermission(.getMemberPermissions, in: team, apiVersion: apiVersion) {
            return permissionError
        }
        
        let payload: [String : Any] = [
            "members" : members.map { $0.payload },
            "hasMore" : false
        ]
        
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func fetchRolesForTeam(with identifier: String?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let identifier = identifier else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: identifier)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound(apiVersion: apiVersion) }
        
        let payload: [String : Any] = [
            "conversation_roles" : team.roles.map { $0.payload }
        ]
        
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func fetchMemberForTeam(withTeamId teamId: String?, userId: String?, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let teamId = teamId, let userId = userId else { return nil }
        let predicate = MockTeam.predicateWithIdentifier(identifier: teamId)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound(apiVersion: apiVersion) }
        guard let member = team.members.first(where: {$0.user.identifier == userId}) else { return .notTeamMember(apiVersion: apiVersion) }
        if let permissionError = ensurePermission(.getMemberPermissions, in: team, apiVersion: apiVersion) {
            return permissionError
        }
        return ZMTransportResponse(payload: member.payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
    
    private func ensurePermission(_ permissions: MockPermissions, in team: MockTeam, apiVersion: APIVersion) -> ZMTransportResponse? {
        guard let selfTeams = selfUser.memberships,
            let member = selfTeams.union(team.members).first
            else { return .notTeamMember(apiVersion: apiVersion) }
        
        guard member.permissions.contains(permissions) else {
            return .operationDenied(apiVersion: apiVersion)
        }
        // All good, no error returned
        return nil
    }

    // MARK: - Legal Hold

    private func approveUserLegalHold(inTeam teamId: String?, forUser userId: String?, payload: ZMTransportData?, method: ZMTransportRequestMethod, apiVersion: APIVersion) -> ZMTransportResponse? {
        // 1) Assert request contents
        guard let teamId = teamId, let userId = userId else { return nil }
        guard method == .methodPUT else { return nil }

        // 2) Check the user in the team
        let predicate = MockTeam.predicateWithIdentifier(identifier: teamId)
        guard let team: MockTeam = MockTeam.fetch(in: managedObjectContext, withPredicate: predicate) else { return .teamNotFound(apiVersion: apiVersion) }
        guard let member = team.members.first(where: {$0.user.identifier == userId}) else { return .notTeamMember(apiVersion: apiVersion) }

        // 3) Check the password
        guard let password = payload?.asDictionary()?["password"] as? String, password == member.user.password else {
            return errorResponse(withCode: 403, reason: "access-denied", apiVersion: apiVersion)
        }

        // 4) Check the legal hold state of the team and user
        guard team.hasLegalHoldService else {
            return errorResponse(withCode: 403, reason: "legalhold-not-enabled", apiVersion: apiVersion)
        }

        switch member.user.legalHoldState {
        case .disabled:
            return errorResponse(withCode: 412, reason: "legalhold-not-pending", apiVersion: apiVersion)
        case .enabled:
            return errorResponse(withCode: 409, reason: "legalhold-already-enabled", apiVersion: apiVersion)
        case .pending(let pendingClient):
            guard member.user.acceptLegalHold(with: pendingClient) == true else {
                return errorResponse(withCode: 400, reason: "legalhold-status-bad", apiVersion: apiVersion)
            }
        }

        return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    private func errorResponse(withCode code: Int, reason: String, apiVersion: APIVersion) -> ZMTransportResponse {
        let payload: NSDictionary = ["label": reason]
        return ZMTransportResponse(payload: payload, httpStatus: code, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    @objc(pushEventsForLegalHoldWithInserted:updated:deleted:shouldSendEventsToSelfUser:)
    public func pushEventsForLegalHold(inserted: Set<NSManagedObject>, updated: Set<NSManagedObject>, deleted: Set<NSManagedObject>, shouldSendEventsToSelfUser: Bool) -> [MockPushEvent] {

        guard shouldSendEventsToSelfUser else { return [] }

        return inserted
            .lazy
            .compactMap { $0 as? MockPendingLegalHoldClient }
            .map(pushEventForPendingLegalHoldDevice)
    }

    private func pushEventForPendingLegalHoldDevice(_ device: MockPendingLegalHoldClient) -> MockPushEvent {
        let payload: NSDictionary = [
            "id": device.user!.identifier,
            "type": "user.legalhold-request",
            "requester": UUID().transportString(),
            "client": ["id": device.identifier!],
            "last_prekey": [
                "id": device.lastPrekey.identifier,
                "key": device.lastPrekey.value
            ]
        ]

        return MockPushEvent(with: payload, uuid: UUID(), isTransient: false, isSilent: false)
    }

}
