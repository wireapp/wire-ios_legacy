//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


private let disableEphemeralSending = false
private let disableEphemeralSendingInGroups = false

extension ZMConversation {
    @objc var hasSyncedMessageDestructionTimeout: Bool {
        switch messageDestructionTimeout {
        case .synced(_)?:
            return true
        default:
            return false
        }
    }
}

@objcMembers final public class ConversationInputBarButtonState: NSObject {

    public var sendButtonHidden: Bool {
        return !hasText || editing || (Settings.shared().disableSendButton && mode != .emojiInput && !markingDown)
    }

    public var hourglassButtonHidden: Bool {
        return hasText || (conversationType != .oneOnOne && disableEphemeralSendingInGroups) || editing || ephemeral || disableEphemeralSending
    }

    public var ephemeralIndicatorButtonHidden: Bool {
        return (conversationType != .oneOnOne && disableEphemeralSendingInGroups) || !ephemeral || disableEphemeralSending
    }

    public var ephemeralIndicatorButtonEnabled: Bool {
        return !ephemeralIndicatorButtonHidden && !syncedMessageDestructionTimeout
    }

    private var hasText: Bool {
        return textLength != 0
    }

    public var ephemeral: Bool {
        return destructionTimeout != 0
    }

    private var textLength: Int = 0
    private var editing: Bool = false
    private var markingDown: Bool = false
    private var destructionTimeout: TimeInterval = 0
    private var conversationType: ZMConversationType = .oneOnOne
    private var mode: ConversationInputBarViewControllerMode = .textInput
    private var syncedMessageDestructionTimeout: Bool = false

    public func update(textLength: Int, editing: Bool, markingDown: Bool, destructionTimeout: TimeInterval, conversationType: ZMConversationType, mode: ConversationInputBarViewControllerMode, syncedMessageDestructionTimeout: Bool) {
        self.textLength = textLength
        self.editing = editing
        self.markingDown = markingDown
        self.destructionTimeout = destructionTimeout
        self.conversationType = conversationType
        self.mode = mode
        self.syncedMessageDestructionTimeout = syncedMessageDestructionTimeout
    }

}
