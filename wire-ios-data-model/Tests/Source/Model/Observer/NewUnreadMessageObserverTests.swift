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

@objc class UnreadMessageTestObserver: NSObject, ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver {

    var unreadMessageNotes: [NewUnreadMessagesChangeInfo] = []
    var unreadKnockNotes: [NewUnreadKnockMessagesChangeInfo] = []

    override init() {
        super.init()
    }

    @objc func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo) {
        self.unreadKnockNotes.append(changeInfo)
    }

    @objc func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo) {
        self.unreadMessageNotes.append(changeInfo)
    }

    func clearNotifications() {
        self.unreadKnockNotes = []
        self.unreadMessageNotes = []
    }
}

class NewUnreadMessageObserverTests: NotificationDispatcherTestBase {

    func processPendingChangesAndClearNotifications() {
        self.uiMOC.saveOrRollback()
        self.testObserver?.clearNotifications()
    }

    var testObserver: UnreadMessageTestObserver!
    var newMessageToken: NSObjectProtocol!
    var newKnocksToken: NSObjectProtocol!

    override func setUp() {
        super.setUp()

        self.testObserver = UnreadMessageTestObserver()
        self.newMessageToken = NewUnreadMessagesChangeInfo.add(observer: self.testObserver, managedObjectContext: self.uiMOC)
        self.newKnocksToken = NewUnreadKnockMessagesChangeInfo.add(observer: self.testObserver, managedObjectContext: self.uiMOC)

    }

    override func tearDown() {
        self.newMessageToken = nil
        self.newKnocksToken = nil
        self.testObserver = nil

        super.tearDown()
    }

    func testThatItNotifiesObserversWhenAMessageMoreRecentThanTheLastReadIsInserted() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        self.uiMOC.saveOrRollback()

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.serverTimestamp = Date()
        msg1.visibleInConversation = conversation

        let msg2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg2.serverTimestamp = Date()
        msg2.visibleInConversation = conversation

        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(self.testObserver.unreadMessageNotes.count, 1)
        XCTAssertEqual(self.testObserver.unreadKnockNotes.count, 0)

        if let note = self.testObserver.unreadMessageNotes.first {
            let expected = NSSet(objects: msg1, msg2)
            XCTAssertEqual(NSSet(array: note.messages), expected)
        }
    }

    func testThatItDoesNotNotifyObserversWhenAMessageOlderThanTheLastReadIsInserted() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.lastReadServerTimeStamp = Date().addingTimeInterval(30)
        self.processPendingChangesAndClearNotifications()

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.visibleInConversation = conversation
        msg1.serverTimestamp = Date()

        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
    }

    func testThatItNotifiesObserversWhenTheConversationHasNoLastRead() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.processPendingChangesAndClearNotifications()

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.visibleInConversation = conversation
        msg1.serverTimestamp = Date()

        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 1)
    }

    func testThatItDoesNotNotifyObserversWhenItHasNoConversation() {

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.serverTimestamp = Date()

        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
    }

    func testThatItNotifiesObserversWhenANewOTRKnockMessageIsInserted() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        self.processPendingChangesAndClearNotifications()

        // when
        let genMsg = GenericMessage(content: Knock.with { $0.hotKnock = false })

        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        do {
            try msg1.setUnderlyingMessage(genMsg)
        } catch {
            XCTFail()
        }
        msg1.visibleInConversation = conversation
        msg1.serverTimestamp = Date()
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(self.testObserver!.unreadKnockNotes.count, 1)
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
        if let note = self.testObserver?.unreadKnockNotes.first {
            let expected = NSSet(object: msg1)
            XCTAssertEqual(NSSet(array: note.messages), expected)
        }
    }
}
