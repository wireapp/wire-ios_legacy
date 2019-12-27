
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMConversation {
    
    @objc
    func addParticipantsOrCreateConversation(_ participants: Set<ZMUser>) -> ZMConversation? {
        guard !participants.isEmpty,
              let userSession = ZMUserSession.shared() else {
            return self
        }

        switch conversationType {
        case .group:
            addOrShowError(participants: participants)
            return self
        case .oneOnOne where participants.count > 1 || (participants.count == 1 && !(connectedUser == participants.first)):
            
            var listOfPeople = Array(participants)
            
            if let connectedUser = connectedUser {
                listOfPeople.append(connectedUser)
            }
            
            return ZMConversation.insertGroupConversation(session: userSession,
                                                          participants: listOfPeople,
                                                          team: ZMUser.selfUser().team)
        default:
            return self
        }
    }

    ///TODO: move to DM
    @objc
    var firstActiveParticipantOtherThanSelf: ZMUser? {
        guard let selfUser = ZMUser.selfUser() else { return localParticipants.first }
        
        return localParticipants.first(where: {$0 != selfUser} )
    }

}
