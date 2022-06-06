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
import WireSyncEngine

extension SessionManager.AccountError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .accountLimitReached:
            return L10n.Localizable.Self.Settings.AddAccount.Error.title
        }
    }

    public var failureReason: String? {
        switch self {
        case .accountLimitReached:
            return L10n.Localizable.Self.Settings.AddAccount.Error.message
        }
    }

}

extension SessionManager.SwitchBackendError: LocalizedError {
    typealias BackendError = L10n.Localizable.UrlAction.SwitchBackend.Error
    public var errorDescription: String? {
        switch self {
        case .invalidBackend:
            return BackendError.InvalidBackend.title
        case .loggedInAccounts:
            
            return BackendError.LoggedIn.title
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidBackend:
            return BackendError.invalidBackend
        case .loggedInAccounts:
            return BackendError.loggedIn
        }
    }
}

extension DeepLinkRequestError: LocalizedError {
    typealias URL_Actions = L10n.Localizable.UrlAction
    public var errorDescription: String? {
        switch self {
        case .invalidUserLink:
            return URL_Actions.InvalidUser.title
        case .invalidConversationLink:
            return URL_Actions.InvalidConversation.title
        case .malformedLink:
            return URL_Actions.InvalidLink.title
        case .notLoggedIn:
            return URL_Actions.AuthorizationRequired.title
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidUserLink:
            return URL_Actions.InvalidUser.message
        case .invalidConversationLink:
            return URL_Actions.InvalidConversation.message
        case .malformedLink:
            return URL_Actions.InvalidLink.message
        case .notLoggedIn:
            return URL_Actions.AuthorizationRequired.message
        }
    }

}

extension CompanyLoginError: LocalizedError {

    public var errorDescription: String? {
        return L10n.Localizable.General.failure
    }

    public var failureReason: String? {
        return L10n.Localizable.Login.Sso.Error.Alert.message(displayCode)
    }

}

extension ConmpanyLoginRequestError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidLink:
            return L10n.Localizable.Login.Sso.startErrorTitle
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidLink:
            return L10n.Localizable.Login.Sso.linkErrorMessage        }
    }
}

extension ConnectToUserError: LocalizedError {

    typealias ConnectionError = L10n.Localizable.Error.Connection

    public var errorDescription: String? {
        return ConnectionError.title
    }

    public var failureReason: String? {
        switch self {
        case .missingLegalholdConsent:
            return ConnectionError.missingLegalholdConsent
        default:
            return ConnectionError.genericError
        }
    }

}

extension UpdateConnectionError: LocalizedError {

    typealias ConnectionError = L10n.Localizable.Error.Connection

    public var errorDescription: String? {
        return ConnectionError.title
    }

    public var failureReason: String? {
        switch self {
        case .missingLegalholdConsent:
            return ConnectionError.missingLegalholdConsent
        default:
            return ConnectionError.genericError
        }
    }

}
