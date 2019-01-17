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
import SafariServices

class SetEmailStepSecondaryView: TeamCreationSecondaryViewDescription {
    let views: [ViewDescriptor] = []
    let learnMore: ButtonDescription

    weak var actioner: AuthenticationActioner?

    init() {
        self.learnMore = ButtonDescription(title: "team.email.button.learn_more".localized, accessibilityIdentifier: "learn_more_button")
        learnMore.buttonTapped = { [weak self] in
            let url = URL.wr_emailInUseLearnMore.appendingLocaleParameter
            self?.actioner?.executeAction(.openURL(url))
        }
    }

    func display(on error: Error) -> ViewDescriptor? {
        guard (error as NSError).userSessionErrorCode == .emailIsAlreadyRegistered else {
            return nil
        }

        return learnMore
    }
}

final class SetEmailStepDescription: TeamCreationStepDescription {

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: TeamCreationSecondaryViewDescription?

    init() {
        backButton = BackButtonDescription()
        mainView = TextFieldDescription(placeholder: "team.email.textfield.placeholder".localized, actionDescription: "team.email.textfield.accessibility".localized, kind: .email)
        headline = "team.email.headline".localized
        subtext = "team.email.subheadline".localized
        secondaryView = SetEmailStepSecondaryView()
    }

}
