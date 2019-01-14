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

class LogInSecondaryView: TeamCreationSecondaryViewDescription {
    let views: [ViewDescriptor]

    weak var actioner: AuthenticationActioner?

    init(credentialsType: AuthenticationCredentialsType, alternativeCredentialsType: AuthenticationCredentialsType?) {
        let loginButtons = LoginButtonsDescription(credentialsType: credentialsType, alternativeCredentialsType: alternativeCredentialsType)
        views = [loginButtons]

        loginButtons.didTapCredentialsTypeChangeButton = { [weak self] in
            self?.actioner?.executeAction(.switchCredentialsType(credentialsType == .phone ? .email : .phone))
        }

        loginButtons.didTapCompanyLoginButton = { [weak self] in
            self?.actioner?.executeAction(.startCompanyLogin)
        }

        loginButtons.didTapResetPasswordButton = { [weak self] in
            self?.actioner?.executeAction(.openURL(.wr_passwordReset))
        }
    }
}


final class LoginButtonsDescription {
    let companyLoginButton: ButtonDescription
    let forgotPasswordButton: ButtonDescription
    let changeFlowTypeButton: ButtonDescription?

    var didTapResetPasswordButton: (() -> ())? = nil
    var didTapCompanyLoginButton: (() -> ())? = nil
    var didTapCredentialsTypeChangeButton: (() -> ())? = nil

    let credentialsType: AuthenticationCredentialsType

    init(credentialsType: AuthenticationCredentialsType, alternativeCredentialsType: AuthenticationCredentialsType?) {
        self.credentialsType = credentialsType
        companyLoginButton = ButtonDescription(title: "signin.company_idp.button.title".localized, accessibilityIdentifier: "companyLoginButton")
        forgotPasswordButton = ButtonDescription(title: "signin.forgot_password".localized, accessibilityIdentifier: "forgotPasswordButton")

        switch alternativeCredentialsType {
        case .email?:
            changeFlowTypeButton = ButtonDescription(title: "registration.signin.email_button.title".localized, accessibilityIdentifier: "loginWithPhoneButton")

        case .phone?:
            changeFlowTypeButton = ButtonDescription(title: "registration.signin.phone_button.title".localized, accessibilityIdentifier: "loginWithEmailButton")

        default:
            changeFlowTypeButton = nil
        }
    }

}

extension LoginButtonsDescription: ViewDescriptor {
    func create() -> UIView {
        companyLoginButton.buttonTapped = didTapCompanyLoginButton
        forgotPasswordButton.buttonTapped = didTapResetPasswordButton
        changeFlowTypeButton?.buttonTapped = didTapCredentialsTypeChangeButton

        let verticalStack = UIStackView(axis: .vertical)
        verticalStack.spacing = 24
        verticalStack.setContentCompressionResistancePriority(.required, for: .vertical)

        let firstLineStack = UIStackView(axis: .horizontal)
        firstLineStack.spacing = 24
        firstLineStack.distribution = .equalCentering

        switch credentialsType {
        case .email:
            firstLineStack.addArrangedSubview(forgotPasswordButton.create())
            firstLineStack.addArrangedSubview(companyLoginButton.create())

            if let changeFlowTypeButton = changeFlowTypeButton {
                verticalStack.addArrangedSubview(changeFlowTypeButton.create())
            }

        case .phone:
            firstLineStack.addArrangedSubview(companyLoginButton.create())

            if let changeFlowTypeButton = changeFlowTypeButton {
                firstLineStack.addArrangedSubview(changeFlowTypeButton.create())
            }
        }

        verticalStack.addArrangedSubview(firstLineStack)
        return verticalStack
    }
}

