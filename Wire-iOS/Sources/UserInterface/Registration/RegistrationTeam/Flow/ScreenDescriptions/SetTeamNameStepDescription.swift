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

final class SetTeamNameStepDescription: TeamCreationStepDescription {

    let controller: UIViewController
    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryViews: [ViewDescriptor]

    init(controller: UIViewController) {
        self.controller = controller
        backButton = BackButtonDescription()
        mainView = TextFieldDescription(placeholder: "Team name", actionDescription: "Set team name", kind: .name)
        headline = "Set team name"
        subtext = "You can always change it later"
        let whatIsWire = ButtonDescription(title: "What is Wire for teams?", accessibilityIdentifier: "wire_for_teams_button")
        whatIsWire.buttonTapped = { [weak controller] in
            let webview = SFSafariViewController(url: URL(string: "https://wire.com/en/create-team/")!)
            controller?.present(webview, animated: true, completion: nil)
        }
        secondaryViews = [whatIsWire]
    }
}

