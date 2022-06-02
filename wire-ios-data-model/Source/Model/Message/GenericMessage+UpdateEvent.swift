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

extension GenericMessage {
    public init?(from updateEvent: ZMUpdateEvent) {
        let base64Content: String?

        switch updateEvent.type {
        case .conversationClientMessageAdd:
            base64Content = updateEvent.payload.string(forKey: "data")
        case .conversationOtrMessageAdd:
            base64Content = updateEvent.payload.dictionary(forKey: "data")?.string(forKey: "text")
        case .conversationOtrAssetAdd:
            base64Content = updateEvent.payload.dictionary(forKey: "data")?.string(forKey: "info")
        default:
            return nil
        }

        var message = GenericMessage(withBase64String: base64Content)

        if case .some(.external(let external)) = message?.content {
            message = GenericMessage(from: updateEvent, withExternal: external)
        }

        guard let unwrappedMessage = message else { return nil }
        self = unwrappedMessage
    }

    static func entityClass(for genericMessage: GenericMessage) -> AnyClass {
        if genericMessage.imageAssetData != nil || genericMessage.assetData != nil {
            return ZMAssetClientMessage.self
        }
        return ZMClientMessage.self
    }
}
