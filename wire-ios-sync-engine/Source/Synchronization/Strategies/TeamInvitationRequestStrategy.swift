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

extension InviteResult {

    init(response: ZMTransportResponse, email: String) {
        let payload = response.payload?.asDictionary()
        let label = payload?["label"] as? String

        switch response.httpStatus {
        case 201:
            self = InviteResult.success(email: email)
        case 403 where label == "too-many-team-invitations":
            self = InviteResult.failure(email: email, error: .tooManyTeamInvitations)
        case 403 where label == "blacklisted-email":
            self = InviteResult.failure(email: email, error: .blacklistedEmail)
        case 403 where label == "invalid-email":
            self = InviteResult.failure(email: email, error: .invalidEmail)
        case 403 where label == "no-identity":
            self = InviteResult.failure(email: email, error: .noIdentity)
        case 403 where label == "no-email":
            self = InviteResult.failure(email: email, error: .noEmail)
        case 409 where label == "email-exists":
            self = InviteResult.failure(email: email, error: .alreadyRegistered)
        default:
            self = InviteResult.failure(email: email, error: .unknown)
        }
    }

}

public final class TeamInvitationRequestStrategy: AbstractRequestStrategy {

    fileprivate weak var teamInvitationStatus: TeamInvitationStatus?

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus, teamInvitationStatus: TeamInvitationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.teamInvitationStatus = teamInvitationStatus
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let teamId = ZMUser.selfUser(in: managedObjectContext).team?.remoteIdentifier,
              let email = teamInvitationStatus?.nextEmail() else { return nil }

        let payload = [
            "email": email,
            "inviter_name": ZMUser.selfUser(in: managedObjectContext).name
        ]

        let request = ZMTransportRequest(path: "/teams/\(teamId.transportString())/invitations", method: .methodPOST, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)

        request.add(ZMCompletionHandler(on: managedObjectContext, block: { [weak self] (response) in
            self?.processResponse(response, for: email)
        }))

        return request
    }

    func processResponse(_ response: ZMTransportResponse, for email: String) {
        switch response.result {
        case .success, .permanentError:
            teamInvitationStatus?.handle(result: InviteResult(response: response, email: email), email: email)
        case .temporaryError, .tryAgainLater, .expired:
            teamInvitationStatus?.retry(email)
        @unknown default:
            fatal("unknown case")
        }
    }

}
