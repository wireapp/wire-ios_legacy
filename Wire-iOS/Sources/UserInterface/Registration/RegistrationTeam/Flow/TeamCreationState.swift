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

enum TeamCreationState {
    case setTeamName
    case setEmail(teamName: String)
    case verifyEmail(teamName: String, email: String)
    case setFullName(teamName: String, email: String, activationCode: String)
    case setPassword(teamName: String, email: String, activationCode: String, fullName: String)
}

extension TeamCreationState {

    var backButtonDescription: BackButtonDescription? {
        switch self {
        case .setTeamName, .setEmail, .setFullName, .setPassword:
            return BackButtonDescription()
        case .verifyEmail:
            return nil
        }
    }

    var mainViewDescription: ViewDescriptor & ValueSubmission {
        switch self {
        case .setTeamName:
            return TextFieldDescription(placeholder: "Team name", kind: .name)
        case .setEmail:
            return TextFieldDescription(placeholder: "Email address", kind: .email)
        case .verifyEmail:
            return VerificationCodeFieldDescription()
        case .setFullName:
            return TextFieldDescription(placeholder: "Name", kind: .name)
        case .setPassword:
            return TextFieldDescription(placeholder: "Password", kind: .password)
        }
    }

    var headline: String {
        switch self {
        case .setTeamName:
            return "Set team name"
        case .setEmail:
            return "Set email"
        case .verifyEmail:
            return "You've got mail"
        case .setFullName:
            return "Set name"
        case .setPassword:
            return "Set password"
        }
    }

    var subtext: String? {
        switch self {
        case .setTeamName:
            return "You can always change it later"
        case .setEmail:
            return nil
        case let .verifyEmail(teamName: _, email: email):
            return "Enter the verification code we sent to \(email)"
        case .setFullName:
            return "This should be your real name"
        case .setPassword:
            return "Please choose a decent password"

        }
    }
}

// MARK: - State transitions
extension TeamCreationState {
    var previousState: TeamCreationState? {
        switch self {
        case .setTeamName:
            return nil
        case .setEmail:
            return .setTeamName
        case let .verifyEmail(teamName: teamName, email: _):
            return .setEmail(teamName: teamName)
        case let .setFullName(teamName: teamName, email: _, activationCode: _):
            return .setEmail(teamName: teamName)
        case let .setPassword(teamName: teamName, email: email, activationCode: activationCode, fullName: _):
            return .setFullName(teamName: teamName, email: email, activationCode: activationCode)
        }
    }

    func nextState(with value: String) -> TeamCreationState? {
        switch self {
        case .setTeamName:
            return .setEmail(teamName: value)
        case let .setEmail(teamName: teamName):
            return .verifyEmail(teamName: teamName, email: value)
        case let .verifyEmail(teamName: teamName, email: email):
            return .setFullName(teamName: teamName, email: email, activationCode: value)
        case let .setFullName(teamName: teamName, email: email, activationCode: activationCode):
            return .setPassword(teamName: teamName, email: email, activationCode: activationCode, fullName: value)
        case .setPassword:
            return nil
        }
    }

}
