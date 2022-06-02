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

// MARK: - GenericMessage

public extension GenericMessage {
    var hasText: Bool {
        return messageData is Text
    }

    var hasConfirmation: Bool {
        return messageData is Confirmation
    }

    var hasReaction: Bool {
        return messageData is WireProtos.Reaction
    }

    var hasAsset: Bool {
        return messageData is WireProtos.Asset
    }

    var hasClientAction: Bool {
        return messageData is ClientAction
    }

    var hasCleared: Bool {
        return messageData is Cleared
    }

    var hasLastRead: Bool {
        return messageData is LastRead
    }

    var hasKnock: Bool {
        return messageData is Knock
    }

    var hasExternal: Bool {
        return messageData is External
    }

    var hasAvailability: Bool {
        return messageData is WireProtos.Availability
    }

    var hasEdited: Bool {
        return messageData is MessageEdit
    }

    var hasDeleted: Bool {
        return messageData is MessageDelete
    }

    var hasCalling: Bool {
        return messageData is Calling
    }

    var hasHidden: Bool {
        return messageData is MessageHide
    }

    var hasLocation: Bool {
        return messageData is Location
    }

    var hasDataTransfer: Bool {
        return messageData is DataTransfer
    }
}

// MARK: - Ephemeral

public extension Ephemeral {
    var hasAsset: Bool {
        return messageData is WireProtos.Asset
    }

    var hasKnock: Bool {
        return messageData is Knock
    }

    var hasLocation: Bool {
        return messageData is Location
    }

    var hasText: Bool {
        return messageData is Text
    }
}
