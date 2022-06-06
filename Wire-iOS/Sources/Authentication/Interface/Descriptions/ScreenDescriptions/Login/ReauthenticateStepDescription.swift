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

/**
 * An authentication step to ask the user to log in again.
 */

class ReauthenticateStepDescription: AuthenticationStepDescription {

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?

    init(prefilledCredentials: AuthenticationPrefilledCredentials?) {
        backButton = BackButtonDescription()
        mainView = EmptyViewDescription()
        headline = L10n.Localizable.Registration.Signin.title

        switch prefilledCredentials?.primaryCredentialsType {
        case .email?:
            if prefilledCredentials?.isExpired == true {
                subtext = L10n.Localizable.SigninLogout.Email.subheadline
            } else {
                subtext = L10n.Localizable.Signin.Email.MissingPassword.subtitle
            }
        case .phone?:
            if prefilledCredentials?.isExpired == true {
                subtext = L10n.Localizable.SigninLogout.Phone.subheadline
            } else {
                subtext = L10n.Localizable.Signin.Phone.MissingPassword.subtitle
            }
        case .none:
            subtext = L10n.Localizable.SigninLogout.subheadline
        }

        secondaryView = LoginSecondaryView()
    }

}
