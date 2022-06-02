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

public enum SSOSettingsError: Error, Equatable {
    case networkFailure
    case malformedData
    case unknown
}

public struct SSOSettings: Codable, Equatable {

    public let ssoCode: UUID?

    private enum CodingKeys: String, CodingKey {
        case ssoCode = "default_sso_code"
    }

    init(ssoCode: UUID?) {
        self.ssoCode = ssoCode
    }

    init?(_ data: Data) {
        let decoder = JSONDecoder()

        do {
            self = try decoder.decode(SSOSettings.self, from: data)
        } catch {
            return nil
        }
    }
}

extension UnauthenticatedSession {

    /// Fetch the SSO settings for the backend.
    ///
    /// This is only interesting if you run against a custom backend.
    ///
    /// - parameter completion: The result closure with the sso settings

    public func fetchSSOSettings(completion: @escaping (Result<SSOSettings>) -> Void) {
        guard let apiVersion = APIVersion.current else {
            return completion(.failure(SSOSettingsError.unknown))
        }

        let path = "/sso/settings"
        let request = ZMTransportRequest(path: path, method: .methodGET, payload: nil, apiVersion: apiVersion.rawValue)

        request.add(ZMCompletionHandler(on: operationLoop.operationQueue!, block: { (response) in

            switch response.result {
            case .success:
                guard let data = response.rawData, let ssoSettings = SSOSettings(data) else {
                    return completion(.failure(SSOSettingsError.malformedData))
                }

                return completion(.success(ssoSettings))
            case .expired, .temporaryError, .tryAgainLater:
                completion(.failure(SSOSettingsError.networkFailure))
            case .permanentError:
                completion(.failure(SSOSettingsError.unknown))
            default:
                completion(.failure(SSOSettingsError.unknown))
            }
        }))

        operationLoop.transportSession.enqueueOneTime(request)
    }

}
