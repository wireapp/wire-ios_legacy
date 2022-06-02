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

import XCTest

@testable import WireDataModel

extension ZMBaseManagedObjectTest {

    var storageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory,
                                 in: .userDomainMask).first!
    }

    func createClientTextMessage() -> ZMClientMessage? {
        return createClientTextMessage(withText: self.name)
    }

    func createClientTextMessage(withText text: String) -> ZMClientMessage? {
        let nonce = UUID.create()
        let message = ZMClientMessage.init(nonce: nonce, managedObjectContext: self.uiMOC)
        let textMessage = GenericMessage(content: Text(content: text, mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce)
        do {
            try message.setUnderlyingMessage(textMessage)
        } catch {
            XCTFail()
        }
        return message
    }

    @objc
    func createCoreDataStack() -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: userIdentifier)
        let stack = CoreDataStack(account: account,
                                  applicationContainer: storageDirectory,
                                  inMemoryStore: shouldUseInMemoryStore,
                                  dispatchGroup: dispatchGroup)

        stack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })

        return stack
    }

    @objc
    func deleteStorageDirectory() throws {
        let files = try FileManager.default
            .contentsOfDirectory(at: storageDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: [])

        try files.forEach({ try FileManager.default.removeItem(at: $0) })
    }
}
