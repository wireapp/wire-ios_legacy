//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel

/**
 * An object holding the configuration of the login prefill.
 */

struct AuthenticationPrefilledCredentials: Equatable {
    /// The primary type of credentials held in the value.
    let primaryCredentialsType: AuthenticationCredentialsType

    /// The raw credentials value.
    let credentials: LoginCredentials

    /// Whether the credentials are expired.
    let isExpired: Bool
}

class LoginSecondaryView: AuthenticationSecondaryViewDescription {

    let views: [ViewDescriptor]
    weak var actioner: AuthenticationActioner?

    init() {
        let resetPasswordButton = ButtonDescription(title: "signin.forgot_password".localized(uppercased: true), accessibilityIdentifier: "forgot_password")
        views = [resetPasswordButton]

        resetPasswordButton.buttonTapped = { [weak self] in
            self?.actioner?.executeAction(.openURL(.wr_passwordReset))
        }
    }

}

/**
 * An authentication step to ask the user for login credentials.
 */

class LogInStepDescription: AuthenticationStepDescription {

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?

    init() {
        backButton = BackButtonDescription()
        mainView = EmptyViewDescription()
        headline = "registration.signin.title".localized
        subtext = nil
        secondaryView = LoginSecondaryView()
    }

}
