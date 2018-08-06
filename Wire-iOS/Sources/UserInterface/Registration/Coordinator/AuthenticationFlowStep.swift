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

typealias AuthenticationStepViewController = UIViewController & AuthenticationCoordinatedViewController

@objc protocol AuthenticationCoordinatedViewController: AuthenticationErrorFeedbackProviding {
    var coordinator: AuthenticationCoordinator? { get set }
}

@objc protocol AuthenticationErrorFeedbackProviding {
    func displayErrorFeedback(_ feedbackAction: AuthenticationErrorFeedbackAction)
}

@objc enum AuthenticationErrorFeedbackAction: Int {
    case showGuidanceDot
}

enum AuthenticationFlowStep {
    case landingScreen
    case reauthenticate(error: Error?, numberOfAccounts: Int)
    case provideEmailCredentials
    case authenticateEmailCredentials(ZMCredentials)
    case clientManagement(clients: [UserClient], credentials: ZMCredentials)

    var allowsUnwind: Bool {
        switch self {
        case .landingScreen, .clientManagement: return false
        default: return true
        }
    }

    var needsInterface: Bool {
        switch self {
        case .authenticateEmailCredentials: return false
        default: return true
        }
    }

}

enum AuthenticationError {

}

protocol _AuthenticationFlowStep {
    var activeCoordinator: AuthenticationCoordinator? { get set }
    func makeViewController() -> UIViewController
}

/*class TeamCreationFlowStep: AuthenticationFlowStep {

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

class AddNewAccountFlowStep: AuthenticationFlowStep {

    weak var activeCoordinator: AuthenticationCoordinator?
    weak var landingDelegate: LandingViewControllerDelegate?

    init(landingDelegate: LandingViewControllerDelegate) {
        self.landingDelegate = landingDelegate
    }

    func makeViewController() -> UIViewController {
        let landingViewController = LandingViewController()
        landingViewController.delegate = landingDelegate
        return landingViewController
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
*/
