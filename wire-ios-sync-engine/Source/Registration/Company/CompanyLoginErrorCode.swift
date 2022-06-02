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

/**
 * Errors that can occur when requesting a company login session from a link.
 */

public enum ConmpanyLoginRequestError: Error, Equatable {
    /// The SSO link provided by the user was invalid.
    case invalidLink
}

/**
 * Errors that can occur within the company login flow.
 */

public enum CompanyLoginError: Error, Equatable {

    case unknownLabel
    case missingRequiredParameter
    case invalidCookie
    case tokenNotFound

    // MARK: - SAML

    case serverErrorUnsupportedSAML
    case badSuccessRedirect
    case badFailureRedirect
    case badUsername
    case badUpstream
    case serverError
    case notFound
    case forbidden
    case noMatchingAuthReq
    case insufficientPermissions

    // MARK: - Metadata

    /// Parses the error label, or fallbacks to the default error if it is not known.
    init(label: String) {
        switch label {
        case "0": self = .unknownLabel
        case "-2063": self = .missingRequiredParameter
        case "-67700": self = .invalidCookie
        case "-25346": self = .tokenNotFound

            // MARK: - SAML

        case "server-error-unsupported-saml": self = .serverErrorUnsupportedSAML
        case "bad-success-redirect": self = .badSuccessRedirect
        case "bad-failure-redirect": self = .badFailureRedirect
        case "bad-username": self = .badUsername
        case "bad-upstream": self = .badUpstream
        case "server-error": self = .serverError
        case "not-found": self = .notFound
        case "forbidden": self = .forbidden
        case "no-matching-auth-req": self = .noMatchingAuthReq
        case "insufficient-permissions": self = .insufficientPermissions
        default:
            self = .unknownLabel
        }
    }

    /// The code to display to the user inside alerts.
    public var displayCode: String {
        switch self {
        case .unknownLabel: return "0"
        case .missingRequiredParameter: return "-2063"
        case .invalidCookie: return "-67700"
        case .tokenNotFound: return "-25346"
        case .serverErrorUnsupportedSAML: return "1"
        case .badSuccessRedirect: return "2"
        case .badFailureRedirect: return "3"
        case .badUsername: return "4"
        case .badUpstream: return "5"
        case .serverError: return "6"
        case .notFound: return "7"
        case .forbidden: return "8"
        case .noMatchingAuthReq: return "9"
        case .insufficientPermissions: return "10"
        }
    }

}
