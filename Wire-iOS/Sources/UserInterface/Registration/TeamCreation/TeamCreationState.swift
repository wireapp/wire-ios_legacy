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
    case enterName
    case setEmail(teamName: String)
    case verifyEmail(teamName: String, email: String)

}

extension TeamCreationState {

    var backButtonDescription: BackButtonDescription? {
        switch self {
        case .enterName, .setEmail:
            return BackButtonDescription()
        case .verifyEmail:
            return nil
        }
    }

    var mainViewDescription: TextFieldDescription {
        switch self {
        case .enterName:
            return TextFieldDescription(placeholder: "Set team name")
        case .setEmail:
            return TextFieldDescription(placeholder: "Set email")
        case .verifyEmail:
            return TextFieldDescription(placeholder: "Code")
        }
    }

    var headline: String {
        switch self {
        case .enterName:
            return "Set team name"
        case .setEmail:
            return "Set email"
        case .verifyEmail:
            return "You've got mail"
        }
    }

    var subtext: String? {
        switch self {
        case .enterName:
            return "You can always\n change \nit later"
        case .setEmail:
            return nil
        case let .verifyEmail(teamName: _, email: email):
            return "Enter the verification code we sent to \(email)"
        }
    }
}


// MARK: - State transitions
extension TeamCreationState {
    var previousState: TeamCreationState? {
        switch self {
        case .enterName:
            return nil
        case .setEmail:
            return .enterName
        case let .verifyEmail(teamName: teamName, email: _):
            return .setEmail(teamName: teamName)
        }
    }

    func nextState(with value: String) -> TeamCreationState? {
        switch self {
        case .enterName:
            return .setEmail(teamName: value)
        case let .setEmail(teamName: teamName):
            return .verifyEmail(teamName: teamName, email: value)
        case .verifyEmail(teamName: _, email: _):
            return nil
        }
    }

}
