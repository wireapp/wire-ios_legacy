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

enum CallInfoViewControllerAccessoryType {
    case none
    case avatar(ZMUser)
    case participantsList(CallParticipantsList)
    
    var showParticipantList: Bool {
        if case .participantsList = self {
            return true
        } else {
            return false
        }
    }
    
    var showAvatar: Bool {
        if case .avatar = self {
            return true
        } else {
            return false
        }
    }
    
    var participants: CallParticipantsList {
        switch self {
        case .participantsList(let participants):
            return participants
        default:
            return []
        }
    }
    
}

extension CallInfoViewControllerAccessoryType: Equatable {
    
    static func ==(lhs: CallInfoViewControllerAccessoryType, rhs: CallInfoViewControllerAccessoryType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.avatar(let lhsUser), .avatar(let rhsUser)):
            return lhsUser == rhsUser
        case (.participantsList(let lhsParticipants), .participantsList(let rhsParticipants)):
            return lhsParticipants == rhsParticipants
        default:
            return false
        }
    }
    
}
