//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

protocol AccessAPIClientProtocol {

    func fetchAccessToken() async throws -> AccessToken

}

@available(iOS 15, *)
final class AccessAPIClient: AccessAPIClientProtocol, Loggable {

    // MARK: - Properties

    private let networkSession: NetworkSessionProtocol

    // MARK: - Life cycle

    init(networkSession: NetworkSessionProtocol) {
        self.networkSession = networkSession
    }

    // MARK: - Methods

    func fetchAccessToken() async throws -> AccessToken {
        logger.trace("fetching access token")
        switch try await networkSession.execute(endpoint: API.fetchAccessToken()) {
        case .success(let accessToken):
            return accessToken

        case .failure(let error):
            throw error
        }
    }

}

struct AccessTokenEndpoint: Endpoint, Loggable {

    // MARK: - Types

    typealias Output = AccessToken

    enum Failure: Error, Equatable {

        case invalidResponse
        case failedToDecodePayload
        case authenticationError
        case unknownError(ErrorResponse)

    }

    // MARK: - Request

    let request = NetworkRequest(
        path: "/access",
        httpMethod: .post,
        contentType: .json,
        acceptType: .json
    )

    // MARK: - Response

    private struct ResponsePayload: Codable {

        let access_token: String
        let expires_in: Int
        let token_type: String
    }

    func parseResponse(_ response: NetworkResponse) -> Swift.Result<Output, Failure> {
        logger.trace("parsing reponse: \(response, privacy: .public)")
        
        switch response {
        case .success(let response) where response.status == 200:
            do {
                logger.trace("decoding response payload")
                let payload = try JSONDecoder().decode(ResponsePayload.self, from: response.data)

                return .success(AccessToken(
                    token: payload.access_token,
                    type: payload.token_type,
                    expiresInSeconds: UInt(payload.expires_in)
                ))
            } catch {
                return .failure(.failedToDecodePayload)
            }

        case .failure(let response):
            switch (response.code, response.label) {
            case (403, "invalid-credentials"):
                return .failure(.authenticationError)

            default:
                return .failure(.unknownError(response))
            }

        default:
            return .failure(.invalidResponse)
        }
    }

}
