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

extension ZMConversation {
    @objc var guestBarState: GuestBarState {
        guard conversationType != .oneOnOne else { return .hidden }

        let otherUsers = activeParticipants
            .array
            .compactMap { $0 as? UserType }
            .filter { !$0.isSelfUser }

        if otherUsers.count == 1, otherUsers[0].isServiceUser {
            return .hidden
        }

        switch (areGuestPresent, areServicesPresent) {
        case (false, false): return .hidden
        case (true, false): return .guestsPresent
        case (false, true): return .servicesPresent
        case (true, true): return .guestsAndServicesPresent
        }
    }
    
    var areGuestPresent: Bool {
        // Check that we have a team and it belongs to the conversation.
        guard let selfUserTeam = ZMUser.selfUser().team, team == selfUserTeam else { return false }
        return activeParticipants
            .lazy
            .compactMap { $0 as? UserType }
            .any { $0.isGuest(in: self) }
    }
    
    var areServicesPresent: Bool {
        return activeParticipants
            .lazy
            .compactMap { $0 as? UserType }
            .any { $0.isServiceUser }
    }
}
