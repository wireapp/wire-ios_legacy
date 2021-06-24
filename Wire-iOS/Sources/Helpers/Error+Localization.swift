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
            return "self.settings.add_account.error.title".localized
        }
    }

    public var failureReason: String? {
        switch self {
        case .accountLimitReached:
            return "self.settings.add_account.error.message".localized
        }
    }

}

extension SessionManager.SwitchBackendError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidBackend:
            return "url_action.switch_backend.error.invalid_backend.title".localized
        case .loggedInAccounts:
            return "url_action.switch_backend.error.logged_in.title".localized
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidBackend:
            return "url_action.switch_backend.error.invalid_backend".localized
        case .loggedInAccounts:
            return "url_action.switch_backend.error.logged_in".localized
        }
    }
}

extension DeepLinkRequestError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidUserLink:
            return "url_action.invalid_user.title".localized
        case .invalidConversationLink:
            return "url_action.invalid_conversation.title".localized
        case .malformedLink:
            return "url_action.invalid_link.title".localized
        case .notLoggedIn:
            return "url_action.authorization_required.title".localized
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidUserLink:
            return "url_action.invalid_user.message".localized
        case .invalidConversationLink:
            return "url_action.invalid_conversation.message".localized
        case .malformedLink:
            return "url_action.invalid_link.message".localized
        case .notLoggedIn:
            return "url_action.authorization_required.message".localized
        }
    }

}

extension CompanyLoginError: LocalizedError {

    public var errorDescription: String? {
        return "general.failure".localized
    }

    public var failureReason: String? {
        return "login.sso.error.alert.message".localized(args: displayCode)
    }

}

extension ConmpanyLoginRequestError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidLink:
            return "login.sso.start_error_title".localized
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidLink:
            return "login.sso.link_error_message".localized
        }
    }
}
