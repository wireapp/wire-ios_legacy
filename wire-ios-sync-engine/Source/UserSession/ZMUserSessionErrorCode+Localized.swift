//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension ZMUserSessionErrorCode: LocalizedError {
    public var errorDescription: String? {
        let bundle = Bundle(for: ZMUserSession.self)
        switch self {
        case .blacklistedEmail:
            return bundle.localizedString(forKey: "user_session.error.blacklisted-email", value: nil, table: "ZMLocalizable")
        case .domainBlocked:
            return bundle.localizedString(forKey: "user_session.error.domain-blocked", value: nil, table: "ZMLocalizable")
        case .emailIsAlreadyRegistered:
            return bundle.localizedString(forKey: "user_session.error.email-exists", value: nil, table: "ZMLocalizable")
        case .invalidEmail:
            return bundle.localizedString(forKey: "user_session.error.invalid-email", value: nil, table: "ZMLocalizable")
        case .invalidActivationCode:
            return bundle.localizedString(forKey: "user_session.error.invalid-code", value: nil, table: "ZMLocalizable")
        case .unknownError:
            return bundle.localizedString(forKey: "user_session.error.unknown", value: nil, table: "ZMLocalizable")
        case .unauthorizedEmail:
            return bundle.localizedString(forKey: "user_session.error.unknown", value: nil, table: "ZMLocalizable")
        default:
            return nil
        }
    }
}
