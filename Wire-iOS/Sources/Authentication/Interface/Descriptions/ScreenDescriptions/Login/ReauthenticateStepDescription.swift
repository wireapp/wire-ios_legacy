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
    let footerView: AuthenticationFooterViewDescription?

    init(prefilledCredentials: AuthenticationPrefilledCredentials?) {
        backButton = BackButtonDescription()
        mainView = EmptyViewDescription()
        headline = "registration.signin.title".localized

        switch prefilledCredentials?.primaryCredentialsType {
        case .email?:
            if prefilledCredentials?.isExpired == true {
                subtext = "signin_logout.email.subheadline".localized
            } else {
                subtext = "signin.email.missing_password.subtitle".localized
            }
        case .phone?:
            if prefilledCredentials?.isExpired == true {
                subtext = "signin_logout.phone.subheadline".localized
            } else {
                subtext = "signin.phone.missing_password.subtitle".localized
            }
        case .none:
            subtext = "signin_logout.subheadline".localized
        }

        secondaryView = nil
        footerView = nil
    }

}
