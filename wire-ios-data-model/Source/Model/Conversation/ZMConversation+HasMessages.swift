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

@objc public extension ZMConversation {

    /// Specifies whether the conversation has content.
    ///
    /// This is an optimized O(1) computation that avoids making Core Data fetch
    /// requests, however it does not guarantee the validity of the result. Use
    /// this in when the need for permformance outweighs the need for accuracy.
    ///
    var estimatedHasMessages: Bool {
        // If we haven't read any messages, then we don't have any.
        guard let lastRead = lastReadServerTimeStamp else { return false }

        // If we've read something, but have never cleared, then we have
        // messages.
        guard let cleared = clearedTimeStamp else { return true }

        // If we've read messages after the cleared date, then we have
        // messages.
        return lastRead > cleared
    }
}
