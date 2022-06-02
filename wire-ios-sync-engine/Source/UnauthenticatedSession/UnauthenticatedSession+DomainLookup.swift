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

public enum DomainLookupError: Error, Equatable {
    case networkFailure
    case malformedData
    case notFound
    case unknown
}

public struct DomainInfo: Codable, Equatable {

    public let configurationURL: URL

    private enum CodingKeys: String, CodingKey {
        case configurationURL = "config_json_url"
    }

    init(configurationURL: URL) {
        self.configurationURL = configurationURL
    }

    init?(_ data: Data) {
        let decoder = JSONDecoder()

        do {
            let domainInfo = try decoder.decode(DomainInfo.self, from: data)

            if domainInfo.configurationURL.scheme != nil {
                self = domainInfo
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension UnauthenticatedSession {

    /// Lookup a domain and fetch its configuration if it's registered in the Wire cloud.
    ///
    /// - parameter domain: Domain to look up (e.g. example.com)
    /// - parameter completion: The result closure will with the result of the lookup.

    public func lookup(domain: String, completion: @escaping (Result<DomainInfo>) -> Void) {
        guard let apiVersion = APIVersion.current else {
            return completion(.failure(DomainLookupError.unknown))
        }

        let path = "/custom-backend/by-domain/\(domain.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
        let request = ZMTransportRequest(path: path, method: .methodGET, payload: nil, apiVersion: apiVersion.rawValue)

        request.add(ZMCompletionHandler(on: operationLoop.operationQueue!, block: { (response) in

            switch response.result {
            case .success:
                guard let data = response.rawData, let domainInfo = DomainInfo(data) else {
                    return completion(.failure(DomainLookupError.malformedData))
                }

                return completion(.success(domainInfo))
            case .expired, .temporaryError, .tryAgainLater:
                completion(.failure(DomainLookupError.networkFailure))
            case .permanentError:
                if response.payloadLabel() == "custom-instance-not-found" {
                    completion(.failure(DomainLookupError.notFound))
                } else {
                    completion(.failure(DomainLookupError.unknown))
                }
            default:
                completion(.failure(DomainLookupError.unknown))
            }
        }))

        operationLoop.transportSession.enqueueOneTime(request)
    }

}
