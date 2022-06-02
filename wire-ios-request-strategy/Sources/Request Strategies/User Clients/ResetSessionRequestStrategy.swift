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

public class ResetSessionRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    fileprivate let keyPathSync: KeyPathObjectSync<ResetSessionRequestStrategy>
    fileprivate let messageSync: ProteusMessageSync<GenericMessageEntity>

    public init(managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                clientRegistrationDelegate: ClientRegistrationDelegate) {

        self.keyPathSync = KeyPathObjectSync(entityName: UserClient.entityName(), \.needsToNotifyOtherUserAboutSessionReset)
        self.messageSync = ProteusMessageSync(context: managedObjectContext,
                                              applicationStatus: applicationStatus)

        super.init(withManagedObjectContext: managedObjectContext,
                   applicationStatus: applicationStatus)

        keyPathSync.transcoder = self
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return messageSync.nextRequest(for: apiVersion)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [keyPathSync] + messageSync.contextChangeTrackers
    }

}

extension ResetSessionRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = UserClient

    func synchronize(_ userClient: UserClient, completion: @escaping () -> Void) {

        guard let conversation = userClient.user?.oneToOneConversation else {
            return
        }

        let message = GenericMessageEntity(conversation: conversation,
                                           message: GenericMessage(clientAction: .resetSession),
                                           completionHandler: nil)

        messageSync.sync(message) { (result, _) in
            switch result {
            case .success:
                userClient.resolveDecryptionFailedSystemMessages()
            case .failure:
                break
            }

            completion()
        }
    }

    func cancel(_ object: UserClient) {

    }

}
