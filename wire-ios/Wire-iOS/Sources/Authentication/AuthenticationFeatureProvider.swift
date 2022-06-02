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

/**
 * An object that provides the available features in the authentication flow.
 */

protocol AuthenticationFeatureProvider {

    /// Whether to allow only email login.
    var allowOnlyEmailLogin: Bool { get }

    /// Whether we allow company login.
    var allowCompanyLogin: Bool { get }

    /// Whether we allow the users to log in with their company manually, or only enable SSO links.
    var allowDirectCompanyLogin: Bool { get }

}

/**
 * Reads the authentication features from the build settings.
 */

class BuildSettingAuthenticationFeatureProvider: AuthenticationFeatureProvider {

    var allowOnlyEmailLogin: Bool {
        #if ALLOW_ONLY_EMAIL_LOGIN
        return true
        #else
        return false
        #endif
    }

    var allowCompanyLogin: Bool {
        return CompanyLoginController.isCompanyLoginEnabled
    }

    var allowDirectCompanyLogin: Bool {
        return allowCompanyLogin && !allowOnlyEmailLogin
    }

}
