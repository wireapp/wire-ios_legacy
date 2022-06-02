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

fileprivate extension AssetRequestFactory {
    static func request(for identifier: String, on queue: ZMSGroupQueue, apiVersion: APIVersion, block: @escaping ZMCompletionHandlerBlock) -> ZMTransportRequest {
        let request = ZMTransportRequest(path: "/assets/v3/\(identifier)", method: .methodDELETE, payload: nil, apiVersion: apiVersion.rawValue)
        request.add(ZMCompletionHandler(on: queue, block: block))
        return request
    }
}

final public class AssetDeletionRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {

    private var requestSync: ZMSingleRequestSync!
    private let identifierProvider: AssetDeletionIdentifierProviderType

    @objc(initWithManagedObjectContext:applicationStatus:identifierProvider:)
    required public init(context: NSManagedObjectContext, applicationStatus: ApplicationStatus, identifierProvider: AssetDeletionIdentifierProviderType) {
        self.identifierProvider = identifierProvider
        super.init(withManagedObjectContext: context, applicationStatus: applicationStatus)
        requestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: context)
    }

    private func handle(response: ZMTransportResponse, for identifier: String) {
        switch response.result {
        case .success: identifierProvider.didDelete(identifier: identifier)
        case .permanentError: identifierProvider.didFailToDelete(identifier: identifier)
        default: break
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        requestSync.readyForNextRequestIfNotBusy()
        return requestSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard sync == requestSync, let identifier = identifierProvider.nextIdentifierToDelete() else { return nil }
        return AssetRequestFactory.request(for: identifier, on: managedObjectContext, apiVersion: apiVersion) { [weak self] response in
            self?.handle(response: response, for: identifier)
        }
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        // no-op
    }
}
