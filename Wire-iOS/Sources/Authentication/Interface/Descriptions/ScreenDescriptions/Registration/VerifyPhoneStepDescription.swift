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

class VerifyPhoneStepSecondaryView: AuthenticationSecondaryViewDescription {
    let views: [ViewDescriptor]
    weak var actioner: AuthenticationActioner?

    init(phoneNumber: String, allowChange: Bool) {
        let resendCode = ButtonDescription(
            title: L10n.Localizable.Team.ActivationCode.Button.resend,
            accessibilityIdentifier: "resend_button")
        let changePhoneNumber = ButtonDescription(
            title: L10n.Localizable.Team.ActivationCode.Button.changePhone,
            accessibilityIdentifier: "change_phone_button")
        views = allowChange ? [resendCode, changePhoneNumber] : [resendCode]

        resendCode.buttonTapped = { [weak self] in
            self?.actioner?.repeatAction()
        }

        changePhoneNumber.buttonTapped = { [weak self] in
            self?.actioner?.executeAction(.unwindState(withInterface: true))
        }
    }
}

final class VerifyPhoneStepDescription: AuthenticationStepDescription {
    let phoneNumber: String
    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?

    init(phoneNumber: String, allowChange: Bool) {
        self.phoneNumber = phoneNumber
        backButton = nil
        mainView = VerificationCodeFieldDescription()
        headline = L10n.Localizable.Team.PhoneActivationCode.headline
        subtext = L10n.Localizable.Team.ActivationCode.subheadline(phoneNumber)
        secondaryView = VerifyPhoneStepSecondaryView(phoneNumber: phoneNumber, allowChange: allowChange)
    }

    func shouldSkipFromNavigation() -> Bool {
        return true
    }
}
