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

@testable import WireSyncEngine

extension MessagingTest {

    public func createClientTextMessage() -> ZMClientMessage? {
        return createClientTextMessageWith(text: self.name)
    }

    public func createClientTextMessageWith(text: String) -> ZMClientMessage? {
        let nonce = UUID.create()
        let message = ZMClientMessage.init(nonce: nonce, managedObjectContext: self.syncMOC)
        let textMessage = GenericMessage(content: Text(content: text,
                                                       mentions: [],
                                                       linkPreviews: [],
                                                       replyingTo: nil), nonce: nonce)
        do {
            try message.setUnderlyingMessage(textMessage)
        } catch {
            return nil
        }
        return message
    }

    @objc
    public func createCoreDataStack() -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: userIdentifier)
        let stack = CoreDataStack(account: account,
                                  applicationContainer: sharedContainerURL,
                                  inMemoryStore: shouldUseInMemoryStore,
                                  dispatchGroup: dispatchGroup)

        stack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })

        return stack
    }
}
