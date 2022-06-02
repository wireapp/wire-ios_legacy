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

protocol Paginatable: Decodable {
    var hasMore: Bool { get }
    var nextStartReference: String? { get }
}

class PaginatedSync<PayloadType: Paginatable>: NSObject, ZMRequestGenerator {

    typealias CompletionHandler = (Swift.Result<PayloadType, PaginatedSyncError>) -> Void

    enum Status: Equatable {
        case fetching(_ state: String)
        case done
    }

    enum PaginationMehod {
        case get
        case post
    }

    enum PaginatedSyncError: Error {
        case permanentError
    }

    let context: NSManagedObjectContext
    let basePath: String
    let pageSize: Int
    let method: PaginationMehod
    var status: Status = .done
    var request: ZMTransportRequest?
    var completionHandler: CompletionHandler?

    init(basePath: String, pageSize: Int, method: PaginationMehod = .get, context: NSManagedObjectContext) {
        self.basePath = basePath
        self.pageSize = pageSize
        self.context = context
        self.method = method
    }

    func fetch(_ completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
        status = .fetching("")
    }

    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard request == nil, case .fetching(let start) = status else {
            return nil
        }

        switch method {
        case .get:
            self.request = getRequest(startReference: start, apiVersion: apiVersion)
        case .post:
            self.request = postRequest(startReference: start, apiVersion: apiVersion)
        }

        request?.add(ZMCompletionHandler(on: context, block: { (response) in
            self.request = nil

            guard let result = PayloadType(response, decoder: .defaultDecoder) else {
                if response.result == .permanentError {
                    self.status = .done
                    self.completionHandler?(.failure(.permanentError))
                }
                return
            }

            if result.hasMore, let nextStartReference = result.nextStartReference {
                self.status = .fetching(nextStartReference)
            } else {
                self.status = .done
            }

            self.completionHandler?(.success(result))
        }))

        return request
    }

    private func getRequest(startReference: String, apiVersion: APIVersion) -> ZMTransportRequest? {
        var queryItems = [URLQueryItem(name: "size", value: String(pageSize))]

        if !startReference.isEmpty {
            queryItems.append(URLQueryItem(name: "start", value: startReference))
        }

        var urlComponents = URLComponents(string: basePath)
        urlComponents?.queryItems = queryItems

        guard let path = urlComponents?.string else {
            return nil
        }

        return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
    }

    private func postRequest(startReference: String, apiVersion: APIVersion) -> ZMTransportRequest? {
        let payload = Payload.PaginationStatus(pagingState: startReference, size: pageSize)

        guard
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        return ZMTransportRequest(path: basePath, method: .methodPOST, payload: payloadAsString as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

}
