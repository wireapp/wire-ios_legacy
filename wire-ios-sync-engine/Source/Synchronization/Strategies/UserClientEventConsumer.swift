//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

/// Consumes self user client update events
///
/// Self user clients are clients belonging to the self user.

@objcMembers
public class UserClientEventConsumer: NSObject, ZMEventConsumer {

    let managedObjectContext: NSManagedObjectContext
    let clientRegistrationStatus: ZMClientRegistrationStatus
    let clientUpdateStatus: ClientUpdateStatus

    public init (managedObjectContext: NSManagedObjectContext,
                 clientRegistrationStatus: ZMClientRegistrationStatus,
                 clientUpdateStatus: ClientUpdateStatus) {
        self.managedObjectContext = managedObjectContext
        self.clientRegistrationStatus = clientRegistrationStatus
        self.clientUpdateStatus = clientUpdateStatus

        super.init()
    }

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        events.forEach(processUpdateEvent)
    }

    fileprivate func processUpdateEvent(_ event: ZMUpdateEvent) {
        switch event.type {
        case .userClientAdd, .userClientRemove:
            processClientListUpdateEvent(event)
        default:
            break
        }
    }

    fileprivate func processClientListUpdateEvent(_ event: ZMUpdateEvent) {
        guard let clientInfo = event.payload["client"] as? [String: AnyObject] else {
            Logging.eventProcessing.error("Client info has unexpected payload")
            return
        }

        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        switch event.type {
        case .userClientAdd:
            if let client = UserClient.createOrUpdateSelfUserClient(clientInfo, context: managedObjectContext) {
                let clientSet: Set<UserClient> = [client]
                selfUser.selfClient()?.addNewClientToIgnored(client)
                selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(clientSet)
            }
        case .userClientRemove:
            let selfClientId = selfUser.selfClient()?.remoteIdentifier
            guard let clientId = clientInfo["id"] as? String else { return }

            if selfClientId != clientId {
                if let clientToDelete = selfUser.clients.filter({ $0.remoteIdentifier == clientId }).first {
                    clientToDelete.deleteClientAndEndSession()
                }
            } else {
                clientRegistrationStatus.didDetectCurrentClientDeletion()
                clientUpdateStatus.didDetectCurrentClientDeletion()
            }
        default: break
        }
    }

}
