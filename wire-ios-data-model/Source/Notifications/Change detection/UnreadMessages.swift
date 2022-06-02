//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

struct UnreadMessages {

    var unsent = Set<ZMMessage>()
    var messages = Set<ZMMessage>()
    var knocks = Set<ZMMessage>()

    var changeInfoByNotification: [Notification.Name: ObjectChangeInfo] {
        var result = [Notification.Name: ObjectChangeInfo]()

        if !unsent.isEmpty {
            result[.NewUnreadUnsentMessage] = NewUnreadUnsentMessageChangeInfo(messages: Array(unsent))
        }

        if !messages.isEmpty {
            result[.NewUnreadMessage] = NewUnreadMessagesChangeInfo(messages: Array(messages))
        }

        if !knocks.isEmpty {
            result[.NewUnreadKnock] = NewUnreadKnockMessagesChangeInfo(messages: Array(knocks))
        }

        return result
    }

}
