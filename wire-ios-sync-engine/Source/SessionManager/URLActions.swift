//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public enum URLAction: Equatable {

    /// Connect to a service user (bot)
    case connectBot(serviceUser: ServiceUserData)

    /// The SSO login sucessfully completed
    case companyLoginSuccess(userInfo: UserInfo)

    /// Start the SSO login flow
    case startCompanyLogin(code: UUID)

    /// Start the login flow
    case startLogin

    /// Join a public conversation
    case joinConversation(key: String, code: String)

    /// Navigate to a conversation
    case openConversation(id: UUID)

    /// The UI search for the user ID and open the profile view for connection request if not connected
    case openUserProfile(id: UUID)

    /// Switch to a custom backend
    case accessBackend(configurationURL: URL)

    public var causesLogout: Bool {
        switch self {
        case .startCompanyLogin: return true
        default: return false
        }
    }

    public var requiresAuthentication: Bool {
        switch self {
        case .joinConversation,
             .openConversation,
             .openUserProfile,
             .connectBot:
             return true
        default: return false
        }
    }

    public var opensDeepLink: Bool {
        switch self {
        case .joinConversation,
             .openConversation,
             .openUserProfile:
            return true
        default: return false
        }
    }
}

extension URLComponents {
    func query(for key: String) -> String? {
        return self.queryItems?.first(where: { $0.name == key })?.value
    }
}

extension URLAction {

    public init?(url: URL, validatingIn defaults: UserDefaults = .shared()) throws {
        guard let components = URLComponents(string: url.absoluteString),
            let host = components.host,
            let scheme = components.scheme,
            scheme.starts(with: "wire") == true else {
                return nil
        }

        switch host {
        case URL.DeepLink.user:
            if let lastComponent = url.pathComponents.last,
                let uuid = UUID(uuidString: lastComponent) {
                self = .openUserProfile(id: uuid)
            } else {
                throw DeepLinkRequestError.invalidUserLink
            }

        case URL.DeepLink.conversationJoin:
            guard
                let key = components.query(for: URLQueryItem.Key.conversationKey),
                let code = components.query(for: URLQueryItem.Key.conversationCode)
            else {
                throw DeepLinkRequestError.malformedLink
            }

            self = .joinConversation(key: key, code: code)

        case URL.DeepLink.conversation:
            if let lastComponent = url.pathComponents.last,
                let uuid = UUID(uuidString: lastComponent) {
                self = .openConversation(id: uuid)
            } else {
                throw DeepLinkRequestError.invalidConversationLink
            }

        case URL.Host.startSSO:
            if let uuidCode = url.pathComponents.last.flatMap(CompanyLoginRequestDetector.requestCode) {
                self = .startCompanyLogin(code: uuidCode)
            } else {
                throw ConmpanyLoginRequestError.invalidLink
            }

        case URL.Host.connect:
            guard let service = components.query(for: URLQueryItem.Key.Connect.service),
                let provider = components.query(for: URLQueryItem.Key.Connect.provider),
                let serviceUUID = UUID(uuidString: service),
                let providerUUID = UUID(uuidString: provider) else {
                    throw DeepLinkRequestError.malformedLink
            }
            self = .connectBot(serviceUser: ServiceUserData(provider: providerUUID, service: serviceUUID))

        case URL.Host.accessBackend:
            guard let config = components.query(for: URLQueryItem.Key.AccessBackend.config), let url = URL(string: config) else {
                throw DeepLinkRequestError.malformedLink
            }
            self = .accessBackend(configurationURL: url)

        case URL.Host.startLogin:
            self = .startLogin

        case URL.Host.login:
            let pathComponents = url.pathComponents

            guard url.pathComponents.count >= 2 else {
                throw ConmpanyLoginRequestError.invalidLink
            }

            switch pathComponents[1] {
            case URL.Path.success:
                guard URLAction.validateURLSchemeRequest(with: components, in: defaults) else {
                    throw CompanyLoginError.tokenNotFound
                }

                guard let cookieString = components.query(for: URLQueryItem.Key.cookie) else {
                    throw CompanyLoginError.missingRequiredParameter
                }
                guard let userID = components.query(for: URLQueryItem.Key.userIdentifier).flatMap(UUID.init) else {
                    throw CompanyLoginError.missingRequiredParameter
                }

                guard let cookieData = HTTPCookie.extractCookieData(from: cookieString, url: url) else {
                    throw CompanyLoginError.invalidCookie
                }

                let userInfo = UserInfo(identifier: userID, cookieData: cookieData)
                self = .companyLoginSuccess(userInfo: userInfo)

            case URL.Path.failure:
                guard URLAction.validateURLSchemeRequest(with: components, in: defaults) else {
                    throw CompanyLoginError.tokenNotFound
                }

                guard let label = components.query(for: URLQueryItem.Key.errorLabel) else {
                    throw CompanyLoginError.missingRequiredParameter
                }

                throw CompanyLoginError(label: label)
            default:
                throw ConmpanyLoginRequestError.invalidLink
            }

        default:
            throw DeepLinkRequestError.malformedLink
        }
    }

    private static func validateURLSchemeRequest(with components: URLComponents, in defaults: UserDefaults) -> Bool {
        guard let storedToken = CompanyLoginVerificationToken.current(in: defaults) else { return false }
        guard let token = components.query(for: URLQueryItem.Key.validationToken).flatMap(UUID.init) else { return false }
        return storedToken.matches(identifier: token)
    }

}

extension URLQueryItem.Key {

    static let conversationKey = "key"
    static let conversationCode = "code"

}
