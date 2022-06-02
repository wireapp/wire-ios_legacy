//
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

    /// Verifies that a sender of an update event is part of the conversation. If they are not,
    /// it means that our local state is out of sync and we need to update the list of participants.
    @objc
    public func verifySender(of updateEvent: ZMUpdateEvent, moc: NSManagedObjectContext) {
        guard let senderUUID = updateEvent.senderUUID else { return }
        let user = ZMUser.fetchOrCreate(with: senderUUID, domain: updateEvent.senderDomain, in: moc)
        addParticipantAndSystemMessageIfMissing(user, date: updateEvent.timestamp?.addingTimeInterval(-0.01))
    }
}
