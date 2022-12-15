//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine

/**
 * The type of credentials to ask when the user is creating or
 * providing credentials.
 */

enum AuthenticationCredentialsType {
    /// Register by phone.
    case phone

    /// Register by email.
    case email
}

/**
 * The context that caused the user to not have a complete history.
 */

enum NoHistoryContext {
    /// The user signed into this device for the first time.
    case newDevice

    /// The user logged out.
    case loggedOut
}

/**
 * Steps of the authentication flow.
 */

indirect enum AuthenticationFlowStep: Equatable {

    // Initial Steps
    case start
    case landingScreen
    case reauthenticate(credentials: LoginCredentials?, numberOfAccounts: Int, isSignedOut: Bool)

    // Sign-In
    case provideCredentials(AuthenticationCredentialsType, AuthenticationPrefilledCredentials?)
    case requestPhoneVerificationCode(phoneNumber: String, isResend: Bool)
    case enterPhoneVerificationCode(phoneNumber: String)
    case enterEmailVerificationCode(email: String, password: String, isResend: Bool)
    case authenticateEmailCredentials(ZMEmailCredentials)
    case authenticatePhoneCredentials(ZMPhoneCredentials)
    case companyLogin
    case switchBackend(url: URL)

    // Post Sign-In
    case noHistory(credentials: ZMCredentials?, context: NoHistoryContext)
    case clientManagement(clients: [UserClient], credentials: ZMCredentials?)
    case deleteClient(clients: [UserClient], credentials: ZMCredentials?)
    case addEmailAndPassword
    case registerEmailCredentials(ZMEmailCredentials, isResend: Bool)
    case pendingEmailLinkVerification(ZMEmailCredentials)
    case pendingInitialSync(next: AuthenticationFlowStep?)

    // Registration
    case createCredentials(UnregisteredUser)
    case sendActivationCode(UnverifiedCredentials, user: UnregisteredUser, isResend: Bool)
    case enterActivationCode(UnverifiedCredentials, user: UnregisteredUser)
    case activateCredentials(UnverifiedCredentials, user: UnregisteredUser, code: String)
    case incrementalUserCreation(UnregisteredUser, IntermediateRegistrationStep)
    case createUser(UnregisteredUser)

    // MARK: - Properties

    /// Whether the authentication steps generates a user interface.
    var needsInterface: Bool {
        switch self {
        // Initial Steps
        case .start: return false
        case .landingScreen: return true
        case .reauthenticate: return true

        // Sign-In
        case .provideCredentials: return true
        case .requestPhoneVerificationCode: return false
        case .enterPhoneVerificationCode: return true
        case .enterEmailVerificationCode: return true
        case .authenticateEmailCredentials: return false
        case .authenticatePhoneCredentials: return false
        case .registerEmailCredentials: return false
        case .companyLogin: return false
        case .switchBackend: return true

        // Post Sign-In
        case .noHistory: return true
        case .clientManagement: return true
        case .deleteClient: return true
        case .addEmailAndPassword: return true
        case .pendingInitialSync: return false
        case .pendingEmailLinkVerification: return true

        // Registration
        case .createCredentials: return true
        case .sendActivationCode: return false
        case .enterActivationCode: return true
        case .activateCredentials: return false
        case .incrementalUserCreation(_, let intermediateStep): return intermediateStep.needsInterface
        case .createUser: return false
        }
    }

}

// MARK: - Intermediate Steps

/**
 * Intermediate steps required for user registration.
 */

enum IntermediateRegistrationStep: Equatable {
    case start, provideMarketingConsent, setName, setPassword

    var needsInterface: Bool {
        switch self {
        case .start: return false
        case .provideMarketingConsent: return false
        default: return true
        }
    }
}
