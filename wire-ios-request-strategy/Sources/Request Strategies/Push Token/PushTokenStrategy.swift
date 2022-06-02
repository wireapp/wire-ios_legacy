//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel

public class PushTokenStrategy: AbstractRequestStrategy, ZMEventConsumer {

    // MARK: - Properties

    private let registerPushTokenActionHandler: RegisterPushTokenActionHandler
    private let removePushTokenActionHandler: RemovePushTokenActionHandler
    private let getPushTokensActionHandler: GetPushTokensActionHandler
    private let actionSync: EntityActionSync

    // MARK: - Life cycle

    @objc
    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        registerPushTokenActionHandler = RegisterPushTokenActionHandler(context: managedObjectContext)
        removePushTokenActionHandler = RemovePushTokenActionHandler(context: managedObjectContext)
        getPushTokensActionHandler = GetPushTokensActionHandler(context: managedObjectContext)

        actionSync = EntityActionSync(actionHandlers: [
            registerPushTokenActionHandler,
            removePushTokenActionHandler,
            getPushTokensActionHandler
        ])

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
    }

    // MARK: - Requests

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return actionSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMEventConsumer

    public func processEvents(
        _ events: [ZMUpdateEvent],
        liveEvents: Bool,
        prefetchResult: ZMFetchRequestBatchResult?
    ) {
        guard liveEvents else { return }
        events.forEach(process(updateEvent:))
    }

    func process(updateEvent event: ZMUpdateEvent) {
        guard event.type == .userPushRemove else { return }

        // expected payload:
        // { "type: "user.push-remove",
        //   "token":
        //    { "transport": "APNS",
        //            "app": "name of the app",
        //          "token": "the token you get from apple"
        //    }
        // }

        // We ignore the payload and remove the local push token
        PushTokenStorage.pushToken = nil
    }
}
