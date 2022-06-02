//
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

class ActionHandler<T: EntityAction>: NSObject, EntityActionHandler, ZMRequestGenerator {
    typealias Action = T

    let context: NSManagedObjectContext

    private var pendingActions: [Action] = []
    private var token: Any?

    init(context: NSManagedObjectContext) {
        self.context = context

        super.init()

        token = Action.registerHandler(self, context: context.notificationContext)
    }

    func performAction(_ action: Action) {
        context.performGroupedBlock {
            self.pendingActions.append(action)
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
    }

    func request(for action: Action, apiVersion: APIVersion) -> ZMTransportRequest? {
        preconditionFailure("request(for:) must be overriden in subclasses")
    }

    func handleResponse(_ response: ZMTransportResponse, action: Action) {
        preconditionFailure("handleResponse(response:action:) must be overriden in subclasses")
    }

    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard !pendingActions.isEmpty else {
            return nil
        }

        let action = pendingActions.removeFirst()
        let request = self.request(for: action, apiVersion: apiVersion)

        request?.add(ZMCompletionHandler(on: context, block: { [weak self] (response) in
            self?.handleResponse(response, action: action)
        }))

        return request
    }
}
