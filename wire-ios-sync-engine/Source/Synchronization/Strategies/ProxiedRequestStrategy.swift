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
import WireTransport

extension ProxiedRequestType {
    var basePath: String {
        switch self {
        case .giphy:
            return "/giphy"
        case .soundcloud:
            return "/soundcloud"
        case .youTube:
            return "/youtube"
        @unknown default:
            fatal("unknown ProxiedRequestType")
        }
    }
}

/// Perform requests to the Giphy search API
public final class ProxiedRequestStrategy: AbstractRequestStrategy {

    static fileprivate let BasePath = "/proxy"

    /// The requests to fulfill
    fileprivate weak var requestsStatus: ProxiedRequestsStatus?

    /// Requests fail after this interval if the network is unreachable
    fileprivate static let RequestExpirationTime: TimeInterval = 20

    @available (*, unavailable, message: "use `init(withManagedObjectContext:applicationStatus:requestsStatus:)` instead")
    override init(withManagedObjectContext moc: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        fatalError()
    }

    public init(withManagedObjectContext moc: NSManagedObjectContext, applicationStatus: ApplicationStatus, requestsStatus: ProxiedRequestsStatus) {
        self.requestsStatus = requestsStatus
        super.init(withManagedObjectContext: moc, applicationStatus: applicationStatus)
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let status = self.requestsStatus else { return nil }

        if let proxyRequest = status.pendingRequests.popFirst() {
            let fullPath = ProxiedRequestStrategy.BasePath + proxyRequest.type.basePath + proxyRequest.path
            let request = ZMTransportRequest(path: fullPath, method: proxyRequest.method, payload: nil, apiVersion: apiVersion.rawValue)
            if proxyRequest.type == .soundcloud {
                request.doesNotFollowRedirects = true
            }
            request.expire(afterInterval: ProxiedRequestStrategy.RequestExpirationTime)
            request.add(ZMCompletionHandler(on: self.managedObjectContext.zm_userInterface, block: { response in
                    proxyRequest.callback?(response.rawData, response.rawResponse, response.transportSessionError as NSError?)
            }))
            request.add(ZMTaskCreatedHandler(on: self.managedObjectContext, block: { taskIdentifier in
                self.requestsStatus?.executedRequests[proxyRequest] = taskIdentifier
            }))

            return request
        }

        return nil
    }

}
