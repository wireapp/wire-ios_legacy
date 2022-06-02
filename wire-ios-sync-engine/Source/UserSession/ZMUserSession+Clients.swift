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

@objc(ZMClientUpdateObserver)
public protocol ClientUpdateObserver: NSObjectProtocol {
    @objc(finishedFetchingClients:)
    func finishedFetching(_ clients: [UserClient])

    @objc(failedToFetchClientsWithError:)
    func failedToFetchClients(_ error: Error)

    @objc(finishedDeletingClients:)
    func finishedDeleting(_ remainingClients: [UserClient])

    @objc(failedToDeleteClientsWithError:)
    func failedToDeleteClients(_ error: Error)
}

extension ZMUserSession {

    /// Fetch all selfUser clients to manage them from the settings screen
    /// The current client must be already registered
    ///
    /// Calling this method without a registered client will fail.

    @objc
    public func fetchAllClients() {
        syncManagedObjectContext.performGroupedBlock {
            self.applicationStatusDirectory?.clientUpdateStatus.needsToFetchClients(andVerifySelfClient: true)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    /// Deletes selfUser clients from the backend

    @objc(deleteClient:withCredentials:)
    public func deleteClient(_ client: UserClient, credentials: ZMEmailCredentials?) {
        client.markForDeletion()
        client.managedObjectContext?.saveOrRollback()

        syncManagedObjectContext.performGroupedBlock {
            self.applicationStatusDirectory?.clientUpdateStatus.deleteClients(withCredentials: credentials)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    /// Adds an observer that is notified when the selfUser clients were successfully fetched and deleted
    ///
    /// - Returns: Token that needs to be stored as long the observer should be active.

    @objc(addClientUpdateObserver:)
    public func addClientUpdateObserver(_ observer: ClientUpdateObserver) -> Any {

        return ZMClientUpdateNotification.addObserver(context: managedObjectContext) { [weak self] (type, clientObjectIDs, error) in
            self?.managedObjectContext.performGroupedBlock {
                switch type {
                case .fetchCompleted:
                    let clients = clientObjectIDs.compactMap({ self?.managedObjectContext.object(with: $0) as? UserClient })
                    observer.finishedFetching(clients)
                case .fetchFailed:
                    if let error = error {
                        observer.failedToFetchClients(error)
                    }
                case .deletionCompleted:
                    let remainingClients = clientObjectIDs.compactMap({ self?.managedObjectContext.object(with: $0) as? UserClient })
                    observer.finishedDeleting(remainingClients)
                case .deletionFailed:
                    if let error = error {
                        observer.failedToDeleteClients(error)
                    }
                }
            }
        }
    }

}
