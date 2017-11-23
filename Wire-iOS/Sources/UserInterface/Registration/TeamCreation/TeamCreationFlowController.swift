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

typealias ValueSubmitted = (String) -> ()

protocol ViewDescriptor: class {
    func create() -> UIView
}

final class TeamCreationFlowController: NSObject {
    var currentState: TeamCreationState = .enterName
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func startFlow() {
        pushCurrentController()
    }

    func createViewController() -> UIViewController {
        let mainView = currentState.mainViewDescription
        mainView.valueSubmitted = { [weak self] (value: String) in
            self?.advanceState(with: value)
        }

        let backButton = currentState.backButtonDescription
        backButton?.buttonTapped = { [weak self] in
            self?.rewindState()
        }

        let controller = TeamCreationStepController(headline: currentState.headline,
                                                    subtext: currentState.subtext,
                                                    mainView: mainView,
                                                    backButton: backButton,
                                                    secondaryViews: currentState.secondaryViews)
        return controller
    }

    func advanceState(with value: String) {
        switch currentState {
        case .enterName:
            currentState = .setEmail(teamName: value)
        case let .setEmail(teamName: teamName):
            currentState = .verifyEmail(teamName: teamName, email: value)
        case .verifyEmail(teamName: _, email: _):
            break
        }
        pushCurrentController()
    }

    func pushCurrentController() {
        let nextController = createViewController()
        self.navigationController.pushViewController(nextController, animated: true)
    }

    func rewindState() {
        switch currentState {
        case .enterName:
            break
        case .setEmail:
            currentState = .enterName
        case let .verifyEmail(teamName: teamName, email: _):
             currentState = .setEmail(teamName: teamName)
        }
        self.navigationController.popViewController(animated: true)
    }
}
