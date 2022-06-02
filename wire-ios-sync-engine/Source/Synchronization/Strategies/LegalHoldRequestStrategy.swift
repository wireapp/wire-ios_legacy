//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

public class LegalHoldRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder, ZMEventConsumer {

    fileprivate let syncStatus: SyncStatus
    fileprivate var singleRequstSync: ZMSingleRequestSync!

    @objc
    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus, syncStatus: SyncStatus) {
        self.syncStatus = syncStatus

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        configuration = [.allowsRequestsDuringSlowSync]
        singleRequstSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard syncStatus.currentSyncPhase == .fetchingLegalHoldStatus else { return nil }

        singleRequstSync.readyForNextRequestIfNotBusy()

        return singleRequstSync.nextRequest(for: apiVersion)
    }

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        guard let teamID = selfUser.team?.remoteIdentifier else {
                // Skip sync phase if the user doesn't belong to a team
                syncStatus.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
                return nil
        }

        guard let userID = selfUser.remoteIdentifier else { return nil }

        return ZMTransportRequest(getFromPath: "/teams/\(teamID.transportString())/legalhold/\(userID.transportString())", apiVersion: apiVersion.rawValue)
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard response.result == .permanentError || response.result == .success else { return }

        if response.result == .success, let payload = response.payload as? [AnyHashable: Any] {
            switch payload["status"] as? String {
            case "pending":
                insertLegalHoldRequest(from: payload)
            case "disabled":
                deleteLegalHoldRequest()
            default:
                break
            }
        }

        syncStatus.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        singleRequstSync.readyForNextRequestIfNotBusy()
    }

    func deleteLegalHoldRequest() {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        selfUser.legalHoldRequestWasCancelled()
    }

    func insertLegalHoldRequest(from payload: [AnyHashable: Any]) {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64

        do {
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: [])
            let request = try decoder.decode(LegalHoldRequest.self, from: jsonPayload)
            selfUser.userDidReceiveLegalHoldRequest(request)
        } catch {
            Logging.eventProcessing.error("Invalid legal hold request payload: \(error)")
        }
    }

    // MARK: - ZMEventConsumer

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        events.forEach(processUpdateEvent)
    }

    fileprivate func processUpdateEvent(_ event: ZMUpdateEvent) {
        switch event.type {
        case .userLegalHoldRequest:
            processLegalHoldRequestEvent(event)
        case .userLegalHoldDisable:
            deleteLegalHoldRequest()
        default:
            break
        }
    }

    fileprivate func processLegalHoldRequestEvent(_ event: ZMUpdateEvent) {
        insertLegalHoldRequest(from: event.payload)
    }

}
