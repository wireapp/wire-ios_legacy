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

/**
 * Valid response actions for authentication events.
 */

enum AuthenticationCoordinatorAction {
    case showLoadingView
    case hideLoadingView
    case unwindState(withInterface: Bool)
    case executeFeedbackAction(AuthenticationErrorFeedbackAction)
    case presentAlert(AuthenticationCoordinatorAlert)
    case presentErrorAlert(AuthenticationCoordinatorErrorAlert)
    case completeBackupStep
    case completeLoginFlow
    case completeRegistrationFlow
    case startPostLoginFlow
    case transition(AuthenticationFlowStep, resetStack: Bool)
    case performPhoneLoginFromRegistration(phoneNumber: String)
    case configureNotifications
    case startIncrementalUserCreation(UnregisteredUser)
    case setMarketingConsent(Bool)
    case completeUserRegistration
    case openURL(URL)
    case repeatAction
    case advanceTeamCreation(String)
    case displayInlineError(NSError)
    case assignRandomProfileImage

    var retainsModal: Bool {
        switch self {
        case .openURL:
            return true
        default:
            return false
        }
    }
}

// MARK: - Alerts

/**
 * A customizable alert to display inside the coordinator's presenter.
 */

struct AuthenticationCoordinatorAlert {
    let title: String?
    let message: String?
    let actions: [AuthenticationCoordinatorAlertAction]
}

/**
 * An action that is part of an authentication coordinator alert.
 */

struct AuthenticationCoordinatorAlertAction {
    let title: String
    let coordinatorActions: [AuthenticationCoordinatorAction]
}

extension AuthenticationCoordinatorAlertAction {
    static let ok: AuthenticationCoordinatorAlertAction = AuthenticationCoordinatorAlertAction(title: "general.ok".localized, coordinatorActions: [])
}

/**
 * A customizable alert to display inside the coordinator's presenter.
 */

struct AuthenticationCoordinatorErrorAlert {
    let error: NSError
    let completionActions: [AuthenticationCoordinatorAction]
}
