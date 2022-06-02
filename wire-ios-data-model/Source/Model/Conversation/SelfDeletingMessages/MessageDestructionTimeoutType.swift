//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// A type representing all the kinds of message destruction timeouts.

public enum MessageDestructionTimeoutType {

    /// For timeouts set (and enforced) by the team admin and apply to all members
    /// of the team. This has highest precedence.

    case team

    /// For timeouts set by the group admin and apply to all participants of the
    /// group.

    case groupConversation

    /// For timeouts set by the self user and only apply to the self user.
    /// This has lowest precedence.

    case selfUser

}
