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
import UIKit

final class EmailLinkVerificationStepDescription: AuthenticationStepDescription {

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription?

    init(emailAddress: String) {
        backButton = BackButtonDescription()
        mainView = EmailLinkVerificationMainView()
        headline = "team.activation_code.headline".localized
        subtext = "registration.verify_email.instructions".localized(args: emailAddress)
        secondaryView = nil
        footerView = VerifyEmailStepSecondaryView(canResend: false)
    }

}

final class EmailLinkVerificationMainView: NSObject, ViewDescriptor, ValueSubmission {
    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?
    var acceptsInput: Bool = true
    var constraints: [NSLayoutConstraint] = []

    func create() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        let label = UILabel()
        let labelPadding = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        let labelContainer = ContentInsetView(label, inset: labelPadding)
        stack.addArrangedSubview(labelContainer)

        label.textAlignment = .center
        label.text = "registration.verify_email.resend.instructions".localized
        label.font = AuthenticationStepController.subtextFont
        label.textColor = UIColor.Team.subtitleColor
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        let button = SolidButtonDescription(title: L10n.Localizable.Team.ActivationCode.Button.resend.capitalized, accessibilityIdentifier: "resend_button")
        button.valueSubmitted = valueSubmitted

        let buttonView = button.create()
        buttonView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        stack.addArrangedSubview(buttonView)

        return stack
    }

}
