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

protocol NetworkSessionProtocol: AnyObject {

    var accessToken: AccessToken? { get set }
    var isAuthenticated: Bool { get }

    func execute<E: Endpoint>(endpoint: E) async throws -> E.Result

}

@available(iOS 15, *)
final class NetworkSession: NSObject, NetworkSessionProtocol, URLSessionTaskDelegate, Loggable {

    // MARK: - Types

    enum NetworkError: Error {

        case invalidResponse
        case invalidRequestURL

    }

    // MARK: - Properties

    var accessToken: AccessToken?

    private let urlSession: URLRequestable
    private let cookieProvider: CookieProvider
    private let environment: BackendEnvironmentProvider

    // MARK: - Life cycle

    init(
        userID: UUID,
        cookieProvider: CookieProvider? = nil,
        urlRequestable: URLRequestable? = nil,
        environment: BackendEnvironmentProvider? = nil
    ) throws {
        self.environment = environment ?? BackendEnvironment.shared

        guard let serverName = self.environment.backendURL.host else {
            throw NotificationServiceError.invalidEnvironment
        }

        self.cookieProvider = cookieProvider ?? ZMPersistentCookieStorage(
            forServerName: serverName,
            userIdentifier: userID
        )

        self.urlSession = urlRequestable ?? URLSession(configuration: .ephemeral)

        super.init()
    }

    // MARK: - Methods

    var isAuthenticated: Bool {
        return cookieProvider.isAuthenticated
    }

    func execute<E: Endpoint>(endpoint: E) async throws -> E.Result {
        logger.trace("executing endpoint: \(String(describing: endpoint), privacy: .public)")
        let response = try await send(request: endpoint.request)
        return endpoint.parseResponse(response)
    }

    func send(request: NetworkRequest) async throws -> NetworkResponse {
        logger.trace("sending request: \(String(describing: request), privacy: .public)")

        guard let url = URL(string: request.path, relativeTo: environment.backendURL) else {
            throw NetworkError.invalidRequestURL
        }

        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue
        urlRequest.addValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(request.acceptType.rawValue, forHTTPHeaderField: "Accept")

        cookieProvider.setRequestHeaderFieldsOn(urlRequest)

        if let accessToken = accessToken {
            urlRequest.addValue(accessToken.headerValue, forHTTPHeaderField: "Authorization")
        }

        logger.info("sending network request: \(urlRequest, privacy: .public)")

        let (data, response) = try await urlSession.data(
            for: urlRequest as URLRequest,
            delegate: self
        )

        if let jsonPayload = String(data: data, encoding: .utf8) {
            logger.info("received response payload for request \(request.path, privacy: .public): \(jsonPayload, privacy: .public)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            logger.info("received error response: \(String(describing: errorResponse), privacy: .public)")
            return .failure(errorResponse)
        } else {
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == request.acceptType.rawValue else {
                throw NetworkError.invalidResponse
            }

            let successResponse = SuccessResponse(
                status: httpResponse.statusCode,
                data: data
            )

            logger.info("received success response: \(String(describing: successResponse), privacy: .public)")

            return .success(successResponse)
        }
    }

}

extension AccessToken {

    var headerValue: String {
        return "\(type) \(token)"
    }

}
