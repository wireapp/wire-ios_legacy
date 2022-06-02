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
import WireProtos

extension UUID {

    public static func isValid(object: Any?) -> Bool {
        guard let string = object as? String else { return false }
        return UUID(uuidString: string) != nil
    }

    public static func isValid(bytes: Data?) -> Bool {
        return bytes?.count == 16
    }

    public static func isValid(array: [Any]?) -> Bool {
        return array?.map(UUID.isValid).contains(false) == false
    }

}

// MARK: - String Formatting

extension String {

    public var isValidAssetID: Bool {

        // Format: https://github.com/wireapp/wire-webapp/blob/dev/app/script/util/ValidationUtil.js

        var assetIDAllowedCharacters = CharacterSet()
        assetIDAllowedCharacters.formUnion(.decimalDigits) // numbers
        assetIDAllowedCharacters.insert(charactersIn: "A" ... "Z") // A-Z
        assetIDAllowedCharacters.insert(charactersIn: "a" ... "z") // a-z
        assetIDAllowedCharacters.insert("-") // hyphen

        return self.trimmingCharacters(in: assetIDAllowedCharacters).isEmpty

    }

    public var isValidBearerToken: Bool {

        // Format: https://github.com/wireapp/wire-webapp/blob/dev/app/script/util/ValidationUtil.js

        let decodedAssetToken = self.removingPercentEncoding ?? self

        var assetTokenAllowedCharacters = CharacterSet()
        assetTokenAllowedCharacters.formUnion(.decimalDigits) // numbers
        assetTokenAllowedCharacters.insert(charactersIn: "A" ... "Z") // A-Z
        assetTokenAllowedCharacters.insert(charactersIn: "a" ... "z") // a-z
        assetTokenAllowedCharacters.insert(charactersIn: "-._~+/") // special characters

        // Check the last non-alphanumerical characters (can be 0-2 equal signs)

        let disallowedSuffix = decodedAssetToken.unicodeScalars.drop(while: assetTokenAllowedCharacters.contains)

        switch String(disallowedSuffix) {
        case "", "=", "==":
            return true

        default:
            return false
        }

    }

}

// MARK: - Specific Validation

// MARK: Generic Message

extension GenericMessage {
    public func validatingFields() -> GenericMessage? {
        guard UUID.isValid(object: messageID), let content = self.content else { return nil }

        switch content {
        case .text:
            guard text.validatingFields() != nil else { return nil }
        case .lastRead:
            guard lastRead.validatingFields() != nil else { return nil }
        case .cleared:
            guard cleared.validatingFields() != nil else { return nil }
        case .hidden:
            guard hidden.validatingFields() != nil else { return nil }
        case .deleted:
            guard deleted.validatingFields() != nil else { return nil }
        case .edited:
            guard edited.validatingFields() != nil else { return nil }
        case .confirmation:
            guard confirmation.validatingFields() != nil else { return nil }
        case .reaction:
            guard reaction.validatingFields() != nil else { return nil }
        case .asset:
            guard asset.validatingFields() != nil else { return nil }
        default:
            break
        }
        return self
    }
}

// MARK: - Text

extension Text {
    public func validatingFields() -> Text? {
        let validMentions = mentions.compactMap { $0.validatingFields() }
        guard validMentions.count == mentions.count else { return nil }
        return self
    }
}

// MARK: Quotes

extension Quote {
    public func validatingFields() -> Quote? {
        return UUID.isValid(object: quotedMessageID) ? self : nil
    }
}

// MARK: Mention

extension WireProtos.Mention {
    public func validatingFields() -> WireProtos.Mention? {
        return UUID.isValid(object: userID) ? self : nil
    }
}

// MARK: Last Read

extension LastRead {
    public func validatingFields() -> LastRead? {
        return UUID.isValid(object: conversationID) ? self : nil
    }
}

// MARK: Cleared

extension Cleared {
    public func validatingFields() -> Cleared? {
        return UUID.isValid(object: conversationID) ? self : nil
    }
}

// MARK: Message Hide

extension MessageHide {
    public func validatingFields() -> MessageHide? {
        guard UUID.isValid(object: conversationID) else { return nil }
        guard UUID.isValid(object: messageID) else { return nil }
        return self
    }
}

// MARK: Message Delete

extension MessageDelete {
    public func validatingFields() -> MessageDelete? {
        return UUID.isValid(object: messageID) ? self : nil
    }
}

// MARK: Message Edit

extension MessageEdit {
    public func validatingFields() -> MessageEdit? {
        return UUID.isValid(object: replacingMessageID) ? self : nil
    }
}

// MARK: Message Confirmation

extension Confirmation {
    public func validatingFields() -> Confirmation? {
        guard UUID.isValid(object: firstMessageID) else { return nil }

        if !moreMessageIds.isEmpty {
            guard UUID.isValid(array: moreMessageIds) else { return nil }
        }

        return self
    }
}

// MARK: Reaction

extension WireProtos.Reaction {
    public func validatingFields() -> WireProtos.Reaction? {
        return UUID.isValid(object: messageID) ? self : nil
    }
}

// MARK: User ID

extension WireProtos.Proteus_UserId {
    public func validatingFields() -> WireProtos.Proteus_UserId? {
        return UUID.isValid(bytes: uuid) ? self : nil
    }
}

// MARK: - Asset

extension WireProtos.Asset {
    public func validatingFields() -> WireProtos.Asset? {
        if hasPreview && preview.hasRemote {
            guard preview.remote.validatingFields() != nil else { return nil }
        }

        if case .uploaded? = status {
            guard uploaded.validatingFields() != nil else { return nil }
        }

        return self
    }
}

extension WireProtos.Asset.RemoteData {
    public func validatingFields() -> WireProtos.Asset.RemoteData? {
        guard assetID.isValidAssetID else { return nil }
        guard assetToken.isValidBearerToken else { return nil }
        return self
    }
}
