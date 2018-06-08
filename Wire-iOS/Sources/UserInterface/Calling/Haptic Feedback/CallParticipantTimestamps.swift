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

final class CallParticipantTimestamps {

    private var participants = Set<UUID>()
    private var participantTimestamps = [UUID: Date]()
    
    func updateParticipants(_ newParticipants: [UUID]) {
        let updated = Set(newParticipants)
        let removed = participants.subtracting(updated)
        let added = updated.subtracting(participants)
        
        removed.forEach {
            Log.callTimestamps.debug("Removing timestamp for \($0)")
            participantTimestamps[$0] = nil
        }
        added.forEach {
            Log.callTimestamps.debug("Adding timestamp for \($0)")
            participantTimestamps[$0] = .init()
        }
        
        participants = updated
    }
    
    subscript(_ uuid: UUID) -> Date? {
        return participantTimestamps[uuid]
    }
    
    subscript(_ user: ZMUser) -> Date? {
        guard let uuid = user.remoteIdentifier else { return nil }
        return self[uuid]
    }
    
}
