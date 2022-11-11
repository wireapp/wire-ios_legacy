//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import CoreCryptoSwift

class CoreCryptoCallbacksWrapper: CoreCryptoSwift.CoreCryptoCallbacks {

    let callbacks: WireDataModel.CoreCryptoCallbacks

    init(callbacks: WireDataModel.CoreCryptoCallbacks) {
        self.callbacks = callbacks
    }

    func authorize(conversationId: ConversationId, clientId: ClientId) -> Bool {
        return callbacks.authorize(conversationId: conversationId, clientId: clientId)
    }

    func userAuthorize(conversationId: CoreCryptoSwift.ConversationId, externalClientId: CoreCryptoSwift.ClientId, existingClients: [CoreCryptoSwift.ClientId]) -> Bool {
        return callbacks.userAuthorize(conversationId: conversationId, externalClientId: externalClientId, existingClients: existingClients)
    }

    func clientIsExistingGroupUser(clientId: CoreCryptoSwift.ClientId, existingClients: [CoreCryptoSwift.ClientId]) -> Bool {
        callbacks.clientIsExistingGroupUser(clientId: clientId, existingClients: existingClients)
    }

}
