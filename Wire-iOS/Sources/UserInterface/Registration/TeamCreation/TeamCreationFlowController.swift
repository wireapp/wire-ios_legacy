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
    var valueSubmitted: ValueSubmitted? { get set }
    func create() -> UIView
}

enum TeamCreationState {
    case enterName
    case setEmail(teamName: String)
}

extension TeamCreationState {
    var mainViewDescription: ViewDescriptor {
        switch self {
        case .enterName:
            return TextFieldDescription(placeholder: "Set team name")
        case .setEmail:
            return TextFieldDescription(placeholder: "Set emal")
        }
    }

    var headline: String {
        switch self {
        case .enterName:
            return "Set team name"
        case .setEmail:
            return "Set email"
        }
    }

    var subtext: String? {
        switch self {
        case .enterName:
            return "You can always change it later"
        case .setEmail:
            return nil
        }
    }

    var secondaryViews: [ViewDescriptor] {
        return []
    }
}

final class TeamCreationFlowController: NSObject {
    var currentState: TeamCreationState = .enterName
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        self.navigationController.delegate = self
    }

    func startFlow() {
        navigationController.isNavigationBarHidden = false
        pushCurrentController()
    }

    func createViewController() -> UIViewController {
        let mainView = currentState.mainViewDescription
        mainView.valueSubmitted = { [weak self] (value: String) in
            self?.advanceState(with: value)
        }

        let controller = TeamCreationStepController(headline: currentState.headline, subtext: currentState.subtext, mainView: mainView, secondaryViews: currentState.secondaryViews)
        return controller
    }

    func advanceState(with value: String) {
        switch currentState {
        case .enterName:
            currentState = .setEmail(teamName: value)
        case .setEmail:
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
        }
    }
}

extension TeamCreationFlowController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

    }
}

