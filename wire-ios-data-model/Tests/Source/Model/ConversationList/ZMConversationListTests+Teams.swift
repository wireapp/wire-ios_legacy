//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import WireDataModel

final class ZMConversationListTests_Teams: ZMBaseManagedObjectTest {

    var dispatcher: NotificationDispatcher!
    var team: Team!
    var otherTeam: Team!

    override func setUp() {
        super.setUp()
        team = createTeam()
        otherTeam = createTeam()
        dispatcher = NotificationDispatcher(managedObjectContext: uiMOC)
    }

    override func tearDown() {
        team = nil
        otherTeam = nil
        dispatcher.tearDown()
        dispatcher = nil
        super.tearDown()
    }

    func testThatItDoesNotReturnTheSelfConversation() {
        // given 
        let group = ZMConversation.insertNewObject(in: uiMOC)
        group.team = team
        group.conversationType = .group
        let selfConversation = ZMConversation.insertNewObject(in: uiMOC)
        selfConversation.conversationType = .self
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.setValue, [group])
    }

    func testThatItReturnConversationsNotInTheCurrentTeam() {
        // given
        let group = ZMConversation.insertNewObject(in: uiMOC)
        group.team = team
        group.conversationType = .group
        let otherGroup = ZMConversation.insertNewObject(in: uiMOC)
        otherGroup.conversationType = .group
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.setValue, [group, otherGroup])
    }

    func testThatItReturnsAllConversationsOfATeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let conversation2 = createGroupConversation(in: team)
        let archived1 = createGroupConversation(in: team, archived: true)
        let archived2 = createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.setValue, [conversation1, conversation2, archived1, archived2])
    }

    func testThatItReturnsAllArchivedConversationsOfATeam() {
        // given
        createGroupConversation(in: team)
        createGroupConversation(in: team)
        let archived1 = createGroupConversation(in: team, archived: true)
        let archived2 = createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.archivedConversations(in: uiMOC)

        // then
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.setValue, [archived1, archived2])
    }

    func testThatItReturnsAllUnarchivedConversationsOfATeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let conversation2 = createGroupConversation(in: team)
        createGroupConversation(in: team, archived: true)
        createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.setValue, [conversation1, conversation2])
    }

    func testThatItReturnsTeamConversationsSorted() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12345678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(500)
        let conversation3 = createGroupConversation(in: team)
        conversation3.lastModifiedDate = startDate.addingTimeInterval(-200)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.arrayValue, [conversation2, conversation1, conversation3])
    }

    func testThatItRecreatesListsAndTokensForTeamConversations() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12345678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate
        uiMOC.saveOrRollback()

        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: self.uiMOC)

        // when inserting a new conversation while in the background
        dispatcher.applicationDidEnterBackground()
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(-10)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        XCTAssertEqual(sut.arrayValue, [conversation1])
        XCTAssertEqual(observer.notifications.count, 0)

        // when refresing the list
        sut.recreate(withAllConversations: [conversation1, conversation2])

        // then
        XCTAssertEqual(sut.arrayValue, [conversation1, conversation2])

        // when forwarding the accumulated changes
        dispatcher.applicationWillEnterForeground()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then the updated snapshot prevents outdated list change notifications
        XCTAssertEqual(observer.notifications.count, 0)
        XCTAssertEqual(sut.arrayValue, [conversation1, conversation2])
    }

    func testThatItUpdatesWhenANewTeamConversationIsInserted() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12345678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate

        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: self.uiMOC)

        // when inserting a new conversation
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(-10)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        XCTAssertEqual(sut.arrayValue, [conversation1, conversation2])
        XCTAssertEqual(observer.notifications.count, 1)
    }

    func testThatDoesUpdateWhenAConversationInADifferentTeamIsInserted() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12345678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate

        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: self.uiMOC)

        // when inserting a new conversation
        let conversation2 = createGroupConversation(in: otherTeam)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(-10)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        XCTAssertEqual(sut.arrayValue, [conversation1, conversation2])
        XCTAssertEqual(observer.notifications.count, 1)
    }

    func testThatItUpdatesWhenNewConversationLastModifiedChangesThroughTheNotificationDispatcher() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12345678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(20)
        let conversation3 = createGroupConversation(in: team)
        conversation3.lastModifiedDate = startDate.addingTimeInterval(-20)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.arrayValue, [conversation2, conversation1, conversation3])
        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: self.uiMOC)

        // when
        XCTAssert(uiMOC.saveOrRollback())
        conversation3.lastModifiedDate = startDate.addingTimeInterval(30)
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.arrayValue, [conversation3, conversation2, conversation1])
        XCTAssertEqual(observer.notifications.count, 1)
    }

    func testThatItUpdatesWhenNewAConversationIsArchivedInATeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let conversation2 = createGroupConversation(in: team)
        let conversation3 = createGroupConversation(in: team)
        let conversation4 = createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // then
        let unarchivedList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssertEqual(unarchivedList.count, 3)
        XCTAssertEqual(unarchivedList.setValue, [conversation2, conversation1, conversation3])

        let archivedList = ZMConversation.archivedConversations(in: uiMOC)
        XCTAssertEqual(archivedList.count, 1)
        XCTAssertEqual(archivedList.arrayValue, [conversation4])

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let unarchivedObserver = ConversationListChangeObserver(conversationList: unarchivedList, managedObjectContext: self.uiMOC)
        let archivedObserver = ConversationListChangeObserver(conversationList: archivedList, managedObjectContext: self.uiMOC)

        // when
        XCTAssert(uiMOC.saveOrRollback())
        conversation2.isArchived = true
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(unarchivedList.count, 2)
        XCTAssertEqual(unarchivedList.setValue, [conversation3, conversation1])
        XCTAssertEqual(unarchivedObserver.notifications.count, 1)

        XCTAssertEqual(archivedList.count, 2)
        XCTAssertEqual(archivedList.setValue, [conversation4, conversation2])
        XCTAssertEqual(archivedObserver.notifications.count, 1)
    }

    func testThatClearingAConversationInATeamMovesItToClearedListInTheTeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let message = try! conversation1.appendText(content: "Text") as! ZMMessage
        message.serverTimestamp = Date()
        uiMOC.saveOrRollback()

        // then
        let activeList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        let archivedList = ZMConversation.archivedConversations(in: uiMOC)
        let clearedList = ZMConversation.clearedConversations(in: uiMOC)

        XCTAssertEqual(activeList.count, 1)
        XCTAssertEqual(activeList.arrayValue, [conversation1])
        XCTAssertEqual(archivedList.count, 0)
        XCTAssertEqual(clearedList.count, 0)
        XCTAssert(uiMOC.saveOrRollback())

        // when
        conversation1.clearMessageHistory()
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(activeList.count, 0)
        XCTAssertEqual(archivedList.count, 0)
        XCTAssertEqual(clearedList.count, 1)
        XCTAssertEqual(clearedList.arrayValue, [conversation1])
    }

    func testThatItDoesNotReturnAConversationAnymoreOnceItGotUnarchived() {
        // given
        let conversation = createGroupConversation(in: team)
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        // then
        do {
            let archivedList = ZMConversation.archivedConversations(in: uiMOC)
            let activeList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
            XCTAssertEqual(archivedList.arrayValue, [conversation])
            XCTAssertEqual(activeList.count, 0)
        }

        // when
        conversation.isArchived = false
        XCTAssert(uiMOC.saveOrRollback())

        // then
        do {
            let archivedList = ZMConversation.archivedConversations(in: uiMOC)
            let activeList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
            XCTAssertEqual(activeList.arrayValue, [conversation])
            XCTAssertEqual(archivedList.count, 0)
        }
    }

    // MARK: - Helper

    private func createTeam() -> Team {
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        return team
    }

    // MARK: - Helper

    @discardableResult func createGroupConversation(in team: Team?, archived: Bool = false) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        conversation.remoteIdentifier = .create()
        conversation.team = team
        conversation.isArchived = archived
        conversation.conversationType = .group
        return conversation
    }

}

fileprivate extension ZMConversationList {

    var setValue: Set<ZMConversation> {
        return Set(arrayValue)
    }

    var arrayValue: [ZMConversation] {
        return self as! [ZMConversation]
    }

}
