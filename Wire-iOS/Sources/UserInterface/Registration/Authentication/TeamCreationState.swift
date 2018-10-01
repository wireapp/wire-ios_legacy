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

enum TeamCreationState: Equatable {
    case setTeamName
    case setEmail(teamName: String)
    case sendEmailCode(teamName: String, email: String, isResend: Bool)
    case verifyEmail(teamName: String, email: String)
    case verifyActivationCode(teamName: String, email: String, activationCode: String)
    case provideMarketingConsent(teamName: String, email: String, activationCode: String)
    case setFullName(teamName: String, email: String, activationCode: String, marketingConsent: Bool)
    case setPassword(teamName: String, email: String, activationCode: String, marketingConsent: Bool, fullName: String)
    case createTeam(teamName: String, email: String, activationCode: String, marketingConsent: Bool, fullName: String, password: String)
    case inviteMembers

    var needsInterface: Bool {
        switch self {
        case .sendEmailCode, .verifyActivationCode: return false
        case .provideMarketingConsent: return false
        case .createTeam: return false
        default: return true
        }
    }

    var allowsUnwind: Bool {
        switch self {
        case .setFullName: return false
        case .inviteMembers: return false
        default: return true
        }
    }
}

// MARK: - State transitions
extension TeamCreationState {

    func nextState(with value: String) -> TeamCreationState? {
        switch self {
        case .setTeamName:
            return .setEmail(teamName: value)
        case let .setEmail(teamName: teamName):
            return .sendEmailCode(teamName: teamName, email: value, isResend: false)
        case .sendEmailCode:
            return nil // transition handled by the responder chain
        case let .verifyEmail(teamName: teamName, email: email):
            return .verifyActivationCode(teamName: teamName, email: email, activationCode: value)
        case let .verifyActivationCode(teamName, email, activationCode):
            return .provideMarketingConsent(teamName: teamName, email: email, activationCode: activationCode)
        case .provideMarketingConsent:
            return nil // handled by the authentication coordinator via actions
        case let .setFullName(teamName: teamName, email: email, activationCode: activationCode, marketingConsent: marketingConsent):
            return .setPassword(teamName: teamName, email: email, activationCode: activationCode, marketingConsent: marketingConsent, fullName: value)
        case let .setPassword(teamName: teamName, email: email, activationCode: activationCode, marketingConsent: marketingConsent, fullName: fullName):
            return .createTeam(teamName: teamName, email: email, activationCode: activationCode, marketingConsent: marketingConsent, fullName: fullName, password: value)
        case .createTeam:
            return nil // transition handled by the responder chain
        case .inviteMembers:
            return nil // last step
        }
    }

}
