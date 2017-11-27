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
    case createTeam(teamName: String, email: String, activationCode: String, fullName: String, password: String)
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
            return .setEmail(teamName: teamName) // We skip the verify email step when coming back
        case let .setPassword(teamName: teamName, email: email, activationCode: activationCode, fullName: _):
            return .setFullName(teamName: teamName, email: email, activationCode: activationCode)
        case let .createTeam(teamName: teamName, email: email, activationCode: activationCode, fullName: fullname, password: _):
            return .setPassword(teamName: teamName, email: email, activationCode: activationCode, fullName: fullname)
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
        case let .setPassword(teamName: teamName, email: email, activationCode: activationCode, fullName: fullName):
            return .createTeam(teamName: teamName, email: email, activationCode: activationCode, fullName: fullName, password: value)
        case .createTeam:
            return nil
        }
    }

}
