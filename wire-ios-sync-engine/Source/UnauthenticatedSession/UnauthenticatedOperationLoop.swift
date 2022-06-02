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
import WireTransport
import WireRequestStrategy

private let log = ZMSLog(tag: "Network")

class UnauthenticatedOperationLoop: NSObject {

    let transportSession: UnauthenticatedTransportSessionProtocol
    let requestStrategies: [RequestStrategy]
    weak var operationQueue: ZMSGroupQueue?
    fileprivate var tornDown = false
    fileprivate var shouldEnqueue = true

    init(transportSession: UnauthenticatedTransportSessionProtocol, operationQueue: ZMSGroupQueue, requestStrategies: [RequestStrategy]) {
        self.transportSession = transportSession
        self.requestStrategies = requestStrategies
        self.operationQueue = operationQueue
        super.init()
        RequestAvailableNotification.addObserver(self)
    }

    deinit {
        precondition(tornDown, "Need to call tearDown before deinit")
    }
}

extension UnauthenticatedOperationLoop: TearDownCapable {
    func tearDown() {
        shouldEnqueue = false
        requestStrategies.forEach { ($0 as? TearDownCapable)?.tearDown() }
        transportSession.tearDown()
        tornDown = true
    }
}

extension UnauthenticatedOperationLoop: RequestAvailableObserver {

    func newRequestsAvailable() {
        var enqueueMore = true
        while enqueueMore && shouldEnqueue {
            let result = transportSession.enqueueRequest(withGenerator: generator)
            enqueueMore = result == .success
            switch result {
            case .maximumNumberOfRequests: log.debug("Maximum number of concurrent requests reached")
            case .nilRequest: log.debug("Nil request generated")
            default: break
            }
        }
    }

    private var generator: ZMTransportRequestGenerator {
        return { [weak self] in
            guard let `self` = self else { return nil }
            guard let apiVersion = APIVersion.current else { return nil }
            let request = (self.requestStrategies as NSArray).nextRequest(for: apiVersion)
            guard let queue = self.operationQueue else { return nil }
            request?.add(ZMCompletionHandler(on: queue) { [weak self] _ in
                self?.newRequestsAvailable()
            })
            return request
        }
    }

}
