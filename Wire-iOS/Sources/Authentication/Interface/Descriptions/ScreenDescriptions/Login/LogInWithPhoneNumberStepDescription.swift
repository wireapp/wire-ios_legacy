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

protocol AuthenticationPrefilledNumberProvider {
    var prefilledNumber: String? { get }
}

final class LogInWithPhoneNumberStepDescription: TeamCreationStepDescription, AuthenticationPrefilledNumberProvider {

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: TeamCreationSecondaryViewDescription?

    let prefilledNumber: String?

    init(prefilledNumber: String? = nil) {
        backButton = BackButtonDescription()
        mainView = EmptyViewDescription()
        headline = "registration.signin.title".localized
        self.prefilledNumber = prefilledNumber

        if prefilledNumber != nil {
            subtext = "signin_logout.phone.subheadline".localized
            secondaryView = SignOutViewDescription(showAlert: true)
        } else {
            subtext = "signin.phone.subheadline".localized
            secondaryView = LogInSecondaryView(credentialsType: .phone, alternativeCredentialsType: .email)
        }
    }

}
