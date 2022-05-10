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
import XCTest

final class NotificationServiceTests: XCTestCase {

    var sut: NotificationService!
    var coreDataFixture: CoreDataFixture!
    var mockConversation: ZMConversation!
    var currentUserIdentifier: UUID!
    var request: UNNotificationRequest!
    var notificatioContent: UNNotificationContent!
    var contentResult: UNNotificationContent?

    var otherUser: ZMUser! {
        return coreDataFixture.otherUser
    }

    var selfUser: ZMUser! {
        return coreDataFixture.selfUser
    }

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        currentUserIdentifier = UUID.create()
        createAccount(with: currentUserIdentifier)
        sut = NotificationService()
        notificatioContent = createNotificatioContent()
        request = UNNotificationRequest(identifier: currentUserIdentifier.uuidString,
                                        content: notificatioContent,
                                        trigger: nil)

    }

    override func tearDown() {
        coreDataFixture = nil
        currentUserIdentifier = nil
        sut = nil
        notificatioContent = nil
        request = nil
        contentResult = nil
        mockConversation = nil

        super.tearDown()
    }

    func testThatNotificationSessionGeneratesNotification() {
        // GIVEN
        sut.didReceive(request, withContentHandler: contentHandlerTest)

        mockConversation = createTeamGroupConversation()
        let note = textNotification(mockConversation, sender: otherUser)

        // WHEN
        sut.notificationSessionDidGenerateNotification(note, unreadConversationCount: 5)

        // THEN
        XCTAssertEqual(note?.content, contentResult)
    }

    func testThatNotificationSessionDoesNotGenerateNotification() {
        // GIVEN
        sut.didReceive(request, withContentHandler: contentHandlerTest)

        mockConversation = createTeamGroupConversation()
        let note = textNotification(mockConversation, sender: otherUser)

        // WHEN
        sut.notificationSessionDidGenerateNotification(note, unreadConversationCount: 5)

        // THEN
        XCTAssertNil(contentResult)
    }




}

// MARK: - Helpers

extension NotificationServiceTests {

    private func createAccount(with id: UUID) {
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            XCTFail()
            fatalError()
        }

        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account = Account(userName: "Test Account", userIdentifier: id)
        manager.addOrUpdate(account)
    }

    private func createNotificatioContent() -> UNMutableNotificationContent{
        let content = UNMutableNotificationContent()
        content.body = "body"
        content.title = "title"

        let storage = ["data": ["user": currentUserIdentifier.uuidString]]
        let userInfo = NotificationUserInfo(storage: storage)

        content.userInfo = userInfo.storage

        return content
    }

    private func textNotification(_ conversation: ZMConversation, sender: ZMUser) -> ZMLocalNotification? {
        let genericMessage = GenericMessage(content: Text(content: "Hello Hello!", linkPreviews: []),
                                            nonce: UUID.create())
        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": sender.remoteIdentifier.transportString(),
            "time": Date().transportString(),
            "data": ["text": try? genericMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())!

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: coreDataFixture.uiMOC)
    }

    func createTeamGroupConversation() -> ZMConversation {
        return ZMConversation.createTeamGroupConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

    private func contentHandlerTest(_ content: UNNotificationContent) {
        contentResult = content
    }

}
