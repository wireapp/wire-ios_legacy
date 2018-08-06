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
 * Steps of the authentication flow.
 */

enum AuthenticationFlowStep {

    // Initial Steps
    case landingScreen
    case reauthenticate(error: Error?, numberOfAccounts: Int)

    // Sign-In
    case provideCredentials
    case authenticateEmailCredentials(ZMCredentials)

    // Post Sign-In
    case noHistory(credentials: ZMCredentials, type: Wire.ContextType)
    case clientManagement(clients: [UserClient], credentials: ZMCredentials)

    // MARK: - Properties

    /// Whether the step can be unwinded.
    var allowsUnwind: Bool {
        switch self {
        case .landingScreen, .clientManagement, .noHistory: return false
        default: return true
        }
    }

    /// Whether the authentication steps generates a user interface.
    var needsInterface: Bool {
        switch self {
        case .authenticateEmailCredentials: return false
        default: return true
        }
    }

}
