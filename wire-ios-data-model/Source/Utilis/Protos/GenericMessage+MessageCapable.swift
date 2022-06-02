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

public protocol MessageCapable {
    func setContent(on message: inout GenericMessage)
    var expectsReadConfirmation: Bool { get set }
}

public protocol EphemeralMessageCapable: MessageCapable {
    func setEphemeralContent(on ephemeral: inout Ephemeral)
}

extension MessageCapable {
    public var expectsReadConfirmation: Bool {
        get {
            return false
        }
        set {}
    }
}

// MARK: - EphemeralMessageCapable

extension Location: EphemeralMessageCapable {
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.location = self
    }

    public func setContent(on message: inout GenericMessage) {
        message.location = self
    }
}

extension Knock: EphemeralMessageCapable {
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.knock = self
    }

    public func setContent(on message: inout GenericMessage) {
        message.knock = self
    }
}

extension Text: EphemeralMessageCapable {
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.text = self
    }

    public func setContent(on message: inout GenericMessage) {
        message.text = self
    }
}

extension WireProtos.Asset: EphemeralMessageCapable {
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.asset = self
    }

    public func setContent(on message: inout GenericMessage) {
        message.asset = self
    }
}

// MARK: - MessageCapable

extension ImageAsset: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.image = self
    }
}

extension Composite: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.composite = self
    }
}

extension ClientAction: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.clientAction = self
    }
}

extension ButtonActionConfirmation: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.buttonActionConfirmation = self
    }
}

extension WireProtos.Availability: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.availability = self
    }
}

extension ButtonAction: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.buttonAction = self
    }
}

extension WireProtos.Reaction: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.reaction = self
    }
}

extension LastRead: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.lastRead = self
    }
}

extension Calling: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.calling = self
    }
}

extension WireProtos.MessageEdit: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.edited = self
    }
}

extension Cleared: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.cleared = self
    }
}

extension MessageHide: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.hidden = self
    }

}

extension MessageDelete: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.deleted = self
    }
}

extension WireProtos.Confirmation: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.confirmation = self
    }
}

extension External: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.external = self
    }
}

extension Ephemeral: MessageCapable {
    public var expectsReadConfirmation: Bool {
        get {
            guard let content = content else { return false }
            switch content {
            case let .text(value):
                return value.expectsReadConfirmation
            case .image:
                return false
            case let .knock(value):
                return value.expectsReadConfirmation
            case let .asset(value):
                return value.expectsReadConfirmation
            case let .location(value):
                return value.expectsReadConfirmation
            }
        }
        set {
            guard let content = content else { return }
            switch content {
            case .text:
                text.expectsReadConfirmation = newValue
            case .image:
                break
            case .knock:
                knock.expectsReadConfirmation = newValue
            case .asset:
                knock.expectsReadConfirmation = newValue
            case .location:
                location.expectsReadConfirmation = newValue
            }
        }
    }

    public func setContent(on message: inout GenericMessage) {
        message.ephemeral = self
    }
}

extension DataTransfer: MessageCapable {
    public func setContent(on message: inout GenericMessage) {
        message.dataTransfer = self
    }
}
