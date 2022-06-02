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

// MARK: - Set message flags

extension GenericMessage {
    var legalHoldStatus: LegalHoldStatus {
        guard let content = content else { return .unknown }
        switch content {
        case .ephemeral:
            return ephemeral.legalHoldStatus
        case .reaction:
            return reaction.legalHoldStatus
        case .knock:
            return knock.legalHoldStatus
        case .text:
            return text.legalHoldStatus
        case .location:
            return location.legalHoldStatus
        case .asset:
            return asset.legalHoldStatus
        default:
            return .unknown
        }
    }

    public mutating func setLegalHoldStatus(_ status: LegalHoldStatus) {
        guard let content = content else { return }
        switch content {
        case .ephemeral:
            self.ephemeral.updateLegalHoldStatus(status)
        case .reaction:
            self.reaction.legalHoldStatus = status
        case .knock:
            self.knock.legalHoldStatus = status
        case .text:
            self.text.legalHoldStatus = status
        case .location:
            self.location.legalHoldStatus = status
        case .asset:
            self.asset.legalHoldStatus = status
        default:
            return
        }
    }

    public mutating func setExpectsReadConfirmation(_ value: Bool) {
        guard let content = content else { return }
        switch content {
        case .ephemeral:
            self.ephemeral.updateExpectsReadConfirmation(value)
        case .knock:
            self.knock.expectsReadConfirmation = value
        case .text:
            self.text.expectsReadConfirmation = value
        case .location:
            self.location.expectsReadConfirmation = value
        case .asset:
            self.asset.expectsReadConfirmation = value
        default:
            return
        }
    }
}

extension Ephemeral {
    public var legalHoldStatus: LegalHoldStatus {
        guard let content = content else { return .unknown }
        switch content {
        case let .text(value):
            return value.legalHoldStatus
        case .image:
            return .unknown
        case let .knock(value):
            return value.legalHoldStatus
        case let .asset(value):
            return value.legalHoldStatus
        case let .location(value):
            return value.legalHoldStatus
        }
    }

    public mutating func updateLegalHoldStatus(_ status: LegalHoldStatus) {
        guard let content = content else { return }
        switch content {
        case .text:
            self.text.legalHoldStatus = status
        case .image:
            break
        case .knock:
            self.knock.legalHoldStatus = status
        case .asset:
            self.asset.legalHoldStatus = status
        case .location:
            self.location.legalHoldStatus = status
        }
    }

    public mutating func updateExpectsReadConfirmation(_ value: Bool) {
        guard let content = content else { return }
        switch content {
        case .text:
            self.text.expectsReadConfirmation = value
        case .image:
            break
        case .knock:
            self.knock.expectsReadConfirmation = value
        case .asset:
            self.asset.expectsReadConfirmation = value
        case .location:
            self.location.expectsReadConfirmation = value
        }
    }
}
