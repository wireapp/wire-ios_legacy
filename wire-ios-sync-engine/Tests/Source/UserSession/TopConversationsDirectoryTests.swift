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
import XCTest
import WireTesting
@testable import WireSyncEngine

class TopConversationsDirectoryTests: MessagingTest {

    var sut: TopConversationsDirectory!
    var topConversationsObserver: FakeTopConversationsDirectoryObserver!
    var topConversationsObserverToken: Any?

    override func setUp() {
        super.setUp()
        self.sut = TopConversationsDirectory(managedObjectContext: self.uiMOC)
        self.topConversationsObserver = FakeTopConversationsDirectoryObserver()
        self.topConversationsObserverToken = self.sut.add(observer: topConversationsObserver)
    }

    override func tearDown() {
        self.topConversationsObserverToken = nil
        self.sut = nil
        super.tearDown()
    }

    func testThatItHasNoResultsWhenCreatedAndNeverFetched() {
        XCTAssertEqual(self.sut.topConversations, [])
    }

    func testThatItSetsTheFetchedTopConversations() {
        // GIVEN
        let conv1 = createConversation(in: uiMOC, fillWithNew: 5)
        let conv2 = createConversation(in: uiMOC, fillWithNew: 15)
        let conv3 = createConversation(in: uiMOC, fillWithNew: 2)

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2, conv1, conv3])
    }

    func testThatOnlyOneOnOneConversationsAreIncluded() {
        // GIVEN
        let conv1 = createConversation(in: uiMOC, fillWithNew: 5)
        let conv2 = createConversation(in: uiMOC, fillWithNew: 15)
        let conv3 = createConversation(in: uiMOC, fillWithNew: 2)

        let user1 = ZMUser.insertNewObject(in: uiMOC), user2 = ZMUser.insertNewObject(in: uiMOC)
        user1.remoteIdentifier = .create()
        user2.remoteIdentifier = .create()
        let groupConv = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [user1, user2])
        groupConv?.remoteIdentifier = .create()

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2, conv1, conv3])
    }

    func testThatItDoesNotConsiderMessagesOlderThanOneMonthInTheSorting() {
        // GIVEN
        let conv1 = createConversation(in: uiMOC, fillWithNew: 5, old: 15)
        let conv2 = createConversation(in: uiMOC, fillWithNew: 10, old: 5)
        let conv3 = createConversation(in: uiMOC, fillWithNew: 2, old: 20)

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2, conv1, conv3])
    }

    func testThatItDoesNotReturnConversationsWithoutMessages() {
        // GIVEN
        createConversation(in: uiMOC, fillWithNew: 0)
        let conv2 = createConversation(in: uiMOC, fillWithNew: 1)
        createConversation(in: uiMOC, fillWithNew: 0)

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2])
    }

    func testThatItDoesNotReturnConversationsWithSystemMessages() throws {
        // GIVEN
        let conv1 = createConversation(in: uiMOC, fillWithNew: 0)
        conv1.appendNewConversationSystemMessage(at: Date(), users: Set())

        let conv2 = createConversation(in: uiMOC, fillWithNew: 1)
        try conv2.appendKnock()

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2])
    }

    func testThatItDoesNotReturnConversationsWithoutMessagesInTheLastMonth() {
        // GIVEN
        createConversation(in: uiMOC, fillWithNew: 0, old: 2)
        let conv2 = createConversation(in: uiMOC, fillWithNew: 1)
        createConversation(in: uiMOC, fillWithNew: 0)

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2])
    }

    func testThatItUpdatesTheConversationsWhenRefreshIsCalledSubsequently() {
        var changesMerger: ManagedObjectContextChangesMerger! = ManagedObjectContextChangesMerger(managedObjectContexts: Set([uiMOC, syncMOC]))
        // To silence warning that changesMerger is not read anywhere
        _ = changesMerger

        // GIVEN
        let conv1 = createConversation(in: uiMOC, fillWithNew: 5, old: 15)
        let conv2 = createConversation(in: uiMOC, fillWithNew: 10, old: 5)
        let conv3 = createConversation(in: uiMOC, fillWithNew: 2, old: 20)

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv2, conv1, conv3])

        // WHEN
        fill(conv3, with: 10)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations, [conv3, conv2, conv1])

        changesMerger = nil
    }

    func testThatItSetsTopConversationFromTheRightContext() {
        // GIVEN
        var expectedConversationsIds: [NSManagedObjectID] = []

        // WHEN
        let conv1 = self.createConversation(in: self.uiMOC, fillWithNew: 2)
        expectedConversationsIds.append(conv1.objectID)
        let conv2 = self.createConversation(in: self.uiMOC, fillWithNew: 1)
        expectedConversationsIds.append(conv2.objectID)

        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.sut.topConversations.map { $0.objectID }, expectedConversationsIds)
        XCTAssertEqual(self.sut.topConversations.compactMap { $0.managedObjectContext }, [self.uiMOC, self.uiMOC])
    }

    func testThatItDoesNotReturnConversationsIfTheyAreDeleted() {

        // GIVEN
        let conv1 = self.createConversation(in: self.uiMOC, fillWithNew: 1)
        let conv2 = self.createConversation(in: self.uiMOC, fillWithNew: 1)

        // WHEN
        self.sut.refreshTopConversations()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.uiMOC.delete(conv1)
        uiMOC.saveOrRollback()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.sut.topConversations, [conv2])
    }

    func testThatItDoesNotReturnConversationsIfTheyAreBlocked() {

        // GIVEN
        let conv1 = self.createConversation(in: self.uiMOC, fillWithNew: 1)
        let conv2 = self.createConversation(in: self.uiMOC, fillWithNew: 1)

        // WHEN
        conv1.connection?.status = .blocked
        sut.refreshTopConversations()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.sut.topConversations, [conv2])
    }

    func testThatItDoesPersistsResults() {

        // GIVEN
        createConversation(in: uiMOC)
        createConversation(in: uiMOC)
        createConversation(in: uiMOC)

        // WHEN
        self.sut.refreshTopConversations()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.uiMOC.saveOrRollback()

        // THEN
        let sut2 = TopConversationsDirectory(managedObjectContext: self.uiMOC)
        XCTAssertEqual(sut2.topConversations, self.sut.topConversations)
    }

    func testThatItLimitsTheNumberOfResults() {
        // GIVEN
        for _ in 0...30 {
            createConversation(in: uiMOC, fillWithNew: 1)
        }

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.topConversations.count, 25)
    }
}

// MARK: - Observation
extension TopConversationsDirectoryTests {

    func testThatItDoesNotNotifyTheObserverIfTheTopConversationsDidNotChange() {

        // GIVEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 0)

        // WHEN
        sut.refreshTopConversations()

        // THEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 0)
    }

    func testThatItNotifiesTheObserverWhenTheTopConversationsDidChange() {

        // GIVEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 0)

        // WHEN
                sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 1)
    }

    func testThatItNotifiesTheObserverWhenTheTopConversationsDidChangeSubsequentially() {

        // GIVEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 0)

        // WHEN
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 1)

        // WHEN
        createConversation(in: uiMOC)
        createConversation(in: uiMOC)
        sut.refreshTopConversations()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(topConversationsObserver.topConversationsDidChangeCallCount, 2)
    }

    func testTopConversationFetchingPerformance() {
//        measured [Time, seconds] average: 0.002, relative standard deviation: 41.686%, values: [0.005234, 0.001380, 0.001704, 0.001740, 0.002017, 0.002177, 0.002234, 0.002532, 0.002773, 0.003041], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "Local Baseline", baselineAverage: 0.011, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100

        measureMetrics(Swift.type(of: self).defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            // given
            (0..<20).forEach {
                self.createConversation(in: self.uiMOC, fillWithNew: $0, old: 5)
            }

            // when measuring
            self.startMeasuring()
            self.sut.refreshTopConversations()
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
            self.stopMeasuring()

            // clean up for the next block execution
            self.uiMOC.executeFetchRequestOrAssert(ZMConversation.sortedFetchRequest()).forEach {
                self.uiMOC.delete($0 as! NSManagedObject)
            }

            XCTAssertTrue(self.uiMOC.saveOrRollback())
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        }
    }

}

// MARK: - Helpers
extension TopConversationsDirectoryTests {

    @discardableResult
    func createConversation(
        in managedObjectContext: NSManagedObjectContext,
        fillWithNew new: Int = 0,
        old: Int = 0,
        file: StaticString = #file,
        line: UInt = #line
        ) -> ZMConversation {

        let conversation = ZMConversation.insertNewObject(in: managedObjectContext)
        conversation.remoteIdentifier = UUID.create()
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: managedObjectContext)
        conversation.connection?.status = .accepted
        fill(conversation, with: (new, old), file: file, line: line)
        managedObjectContext.saveOrRollback()
        return conversation
    }

    func fill(_ conversation: ZMConversation, with messageCount: Int, file: StaticString = #file, line: UInt = #line) {
        fill(conversation, with: (messageCount, 0), file: file, line: line)
    }

    func fill(_ conversation: ZMConversation, with messageCount: (new: Int, old: Int), file: StaticString = #file, line: UInt = #line) {
        guard messageCount.new > 0 || messageCount.old > 0 else { return }
        (0..<messageCount.new).forEach {
            try! conversation.appendText(content: "Message #\($0)")
        }

        (0..<messageCount.old).forEach {
            let message = try! conversation.appendText(content: "Message #\($0)") as! ZMMessage
            message.serverTimestamp = Date(timeIntervalSince1970: TimeInterval($0 * 100))
        }

        XCTAssertTrue(uiMOC.saveOrRollback(), file: file, line: line)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2), file: file, line: line)
    }
}

class FakeTopConversationsDirectoryObserver: TopConversationsDirectoryObserver {

    var topConversationsDidChangeCallCount = 0

    func topConversationsDidChange() {
        topConversationsDidChangeCallCount += 1
    }

}
