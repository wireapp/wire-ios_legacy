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

protocol AuthenticationFlowStep {
    var activeCoordinator: AuthenticationCoordinator? { get set }
    func makeViewController() -> UIViewController
}

class TeamCreationFlowStep: AuthenticationFlowStep {

    weak var activeCoordinator: AuthenticationCoordinator?

    func makeViewController() -> UIViewController {
        //let flowController = TeamCreationFlowController(navigationController: navigationController, registrationStatus: registrationStatus)
        //flowController.registrationDelegate = appStateController
        //viewController = navigationController
        return UIViewController()
    }

}

class ReauthenticationFlowStep: AuthenticationFlowStep {

    let signInError: Error?
    let numberOfAccounts: Int

    weak var activeCoordinator: AuthenticationCoordinator?

    init(signInError: Error?, numberOfAccounts: Int) {
        self.signInError = signInError
        self.numberOfAccounts = numberOfAccounts
    }

    func makeViewController() -> UIViewController {
        let registrationViewController = RegistrationViewController()
        //registrationViewController.delegate = appStateController
        registrationViewController.shouldHideCancelButton = numberOfAccounts <= 1
        registrationViewController.signInError = signInError
        return registrationViewController
    }

}

class AddNewAccountFlowStep: AuthenticationFlowStep, LandingViewControllerDelegate {

    weak var activeCoordinator: AuthenticationCoordinator?

    func makeViewController() -> UIViewController {
        let landingViewController = LandingViewController()
        landingViewController.delegate = self
        return landingViewController
    }

    func landingViewControllerDidChooseLogin() {
        let initiateLogin = InitiateLoginFlowStep()
        activeCoordinator?.push(step: initiateLogin)
    }

    func landingViewControllerDidChooseCreateAccount() {

    }

    func landingViewControllerDidChooseCreateTeam() {

    }

    func landingViewControllerNeedsToPresentNoHistoryFlow(with context: ContextType) {
        // no-op
    }

}

class InitiateLoginFlowStep: AuthenticationFlowStep {

    weak var activeCoordinator: AuthenticationCoordinator?

    func makeViewController() -> UIViewController {
        let loginViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
        //loginViewController.delegate = appStateController
        loginViewController.shouldHideCancelButton = true
        return loginViewController
    }

}
