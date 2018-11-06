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

extension ZMConversationMessage {

    func formattedOriginalReceivedDate() -> String? {
        guard let timestamp = self.serverTimestamp else {
            return nil
        }

        let formattedDate: String

        if Calendar.current.isDateInToday(timestamp) {
            formattedDate = Message.shortTimeFormatter.string(from: timestamp)
        } else {
            formattedDate = Message.shortDateFormatter.string(from: timestamp)
        }

        return "content.message.reply.original_timestamp".localized(args: formattedDate)
    }

    func formattedReceivedDate() -> String? {
        return serverTimestamp.map(formattedDate)
    }

    func formattedEditedDate() -> String? {
        return updatedAt.map(formattedDate)
    }

    func formattedDate(_ date: Date) -> String {
        let oneDayInSeconds = 24.0 * 60.0 * 60.0
        let shouldShowDate = fabs(date.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate) > oneDayInSeconds
        if shouldShowDate {
            return Message.shortDateTimeFormatter.string(from: date)
        } else {
            return Message.shortTimeFormatter.string(from: date)
        }
    }
}

extension ZMSystemMessageData {

    func callDurationString() -> String? {
        guard systemMessageType == .performedCall, duration > 0 else { return nil }
        return Message.callDurationFormatter.string(from: duration)
    }
}
