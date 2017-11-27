//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

protocol VerifyEmailStepDescriptionDelegate: class {
    func resendActivationCode(to email: String)
    func changeEmail()
}

final class VerifyEmailStepDescription: TeamCreationStepDescription {
    let email: String
    weak var delegate: VerifyEmailStepDescriptionDelegate?

    init(email: String, delegate: VerifyEmailStepDescriptionDelegate) {
        self.email = email
        self.delegate = delegate
    }

    var backButtonDescription: BackButtonDescription? {
        return nil
    }

    var mainViewDescription: ViewDescriptor & ValueSubmission {
        return VerificationCodeFieldDescription()
    }

    var headline: String {
        return "You've got mail"
    }

    var subtext: String? {
        return "Enter the verification code we sent to \(email)"
    }

    var secondaryViews: [ViewDescriptor] {
        let resendCode = ButtonDescription(title: "Resend code", accessibilityIdentifier: "resend_button")
        resendCode.buttonTapped = { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.resendActivationCode(to: self.email)
        }
        let changeEmail = ButtonDescription(title: "Change Email", accessibilityIdentifier: "change_email_button")
        changeEmail.buttonTapped = { [weak self] in
            self?.delegate?.changeEmail()
        }
        return [resendCode, changeEmail]
    }
}
