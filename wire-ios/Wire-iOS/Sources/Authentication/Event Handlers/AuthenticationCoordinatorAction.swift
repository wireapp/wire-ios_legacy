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
import UIKit
import WireSyncEngine

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
    case transition(AuthenticationFlowStep, mode: AuthenticationStateController.StateChangeMode)
    case performPhoneLoginFromRegistration(phoneNumber: String)
    case requestEmailVerificationCode(email: String, password: String)
    case configureNotifications
    case startIncrementalUserCreation(UnregisteredUser)
    case setMarketingConsent(Bool)
    case completeUserRegistration
    case openURL(URL)
    case repeatAction
    case displayInlineError(NSError)
    case assignRandomProfileImage
    case continueFlowWithLoginCode(String)
    case switchCredentialsType(AuthenticationCredentialsType)
    case startRegistrationFlow(UnverifiedCredentials)
    case startLoginFlow(AuthenticationLoginRequest)
    case setUserName(String)
    case setUserPassword(String)
    case updateBackendEnvironment(url: URL)
    case startCompanyLogin(code: UUID?)
    case startSSOFlow
    case startBackupFlow
    case signOut(warn: Bool)
    case addEmailAndPassword(ZMEmailCredentials)

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
    let style: UIAlertAction.Style

    init(title: String, coordinatorActions: [AuthenticationCoordinatorAction], style: UIAlertAction.Style = .default) {
        self.title = title
        self.coordinatorActions = coordinatorActions
        self.style = style
    }
}

extension AuthenticationCoordinatorAlertAction {
    static let ok: AuthenticationCoordinatorAlertAction = AuthenticationCoordinatorAlertAction(title: "general.ok".localized, coordinatorActions: [])
    static let cancel: AuthenticationCoordinatorAlertAction = AuthenticationCoordinatorAlertAction(title: "general.cancel".localized, coordinatorActions: [], style: .cancel)
}

/**
 * A customizable alert to display inside the coordinator's presenter.
 */

struct AuthenticationCoordinatorErrorAlert {
    let error: NSError
    let completionActions: [AuthenticationCoordinatorAction]
}

enum AuthenticationLoginRequest {
    case email(address: String, password: String)
    case phoneNumber(String)
}
