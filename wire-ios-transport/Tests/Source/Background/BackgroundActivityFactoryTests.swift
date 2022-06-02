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

import UIKit
import XCTest
import WireTesting
@testable import WireTransport

class BackgroundActivityFactoryTests: XCTestCase {

    var factory: BackgroundActivityFactory!
    var activityManager: MockBackgroundActivityManager!

    override func setUp() {
        super.setUp()
        activityManager = MockBackgroundActivityManager()
        factory = BackgroundActivityFactory.shared
        factory.backgroundTaskTimeout = 2
        factory.activityManager = activityManager
        factory.mainQueue = .global()
    }

    override func tearDown() {
        activityManager.reset()
        factory.reset()
        activityManager = nil
        factory = nil
        super.tearDown()
    }

    func testThatItCreatesActivity() {
        // WHEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")

        // THEN
        XCTAssertNotNil(activity)
        XCTAssertEqual(activity?.name, "Activity 1")
        XCTAssertTrue(factory.isActive)
        XCTAssertEqual(activityManager.numberOfTasks, 1)
    }

    func testThatItCreatesOnlyOneSystemTaskWithMultipleActivities() {
        // WHEN
        _ = factory.startBackgroundActivity(withName: "Activity 1")
        _ = factory.startBackgroundActivity(withName: "Activity 2")

        // THEN
        XCTAssertTrue(factory.isActive)
        XCTAssertEqual(activityManager.numberOfTasks, 1)
        XCTAssertEqual(factory.activities.count, 2)
    }

    func testThatItDoesNotCreateActivityIfTheAppIsBeingSuspended() {
        // GIVEN
        activityManager.triggerExpiration()

        // WHEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")

        // THEN
        XCTAssertNil(activity)
        XCTAssertNil(factory.currentBackgroundTask)
    }

    func testThatItRemovesTaskWhenItEnds() {
        // GIVEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")!

        // WHEN
        factory.endBackgroundActivity(activity)

        // THEN
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }

    func testThatItDoesNotRemoveTaskWhenItEndsIfThereAreMoreTasks() {
        // GIVEN
        let activity1 = factory.startBackgroundActivity(withName: "Activity 1")!
        let activity2 = factory.startBackgroundActivity(withName: "Activity 2")!

        // WHEN
        factory.endBackgroundActivity(activity1)

        // THEN
        XCTAssertTrue(factory.isActive)
        XCTAssertEqual(factory.activities, [activity2])
        XCTAssertEqual(activityManager.numberOfTasks, 1)
    }

    func testThatItCallsExpirationHandlerOnCreatedActivities() {
        // GIVEN
        let expirationExpectation = expectation(description: "The expiration handler is called.")

        let activity = factory.startBackgroundActivity(withName: "Activity 1") {
            expirationExpectation.fulfill()
        }

        // WHEN
        XCTAssertNotNil(activity)
        activityManager.triggerExpiration()

        // THEN
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }
    
    func testItNotifiesThatAllBackgroundActivitiesEnded_WhenTaskExpires() {
        // GIVEN
        let endHandlerExpectation = expectation(description: "The end handler is called.")
        let activity = factory.startBackgroundActivity(withName: "Activity 1") {}
        
        factory.notifyWhenAllBackgroundActivitiesEnd {
            endHandlerExpectation.fulfill()
        }

        // WHEN
        XCTAssertNotNil(activity)
        activityManager.triggerExpiration()

        // THEN
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }
    
    func testItNotifiesThatAllBackgroundActivitiesEnded_WhenTaskEnds() throws {
        // GIVEN
        let endHandlerExpectation = expectation(description: "The end handler is called.")
        let activity = try XCTUnwrap(factory.startBackgroundActivity(withName: "Activity 1") {})
        
        factory.notifyWhenAllBackgroundActivitiesEnd {
            endHandlerExpectation.fulfill()
        }

        // WHEN
        factory.endBackgroundActivity(activity)

        // THEN
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }
    
    func testItDoesntNotifyThatAllBackgroundActivitiesEnded_WhenTaskEndsIfThereAreMoreTasks() throws {
        // GIVEN
        let activity1 = try XCTUnwrap(factory.startBackgroundActivity(withName: "Activity 1") {})
        _ = try XCTUnwrap(factory.startBackgroundActivity(withName: "Activity 2") {})
        
        factory.notifyWhenAllBackgroundActivitiesEnd {
            XCTFail()
        }

        // WHEN
        factory.endBackgroundActivity(activity1)

        // THEN
        XCTAssertTrue(factory.isActive)
        XCTAssertFalse(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 1)
    }

    func testItEndsActivities_WhenTheCustomTimeoutHasExpiredInTheBackground() {
        // GIVEN
        let _ = factory.startBackgroundActivity(withName: "Activity 1")!
        let expirationExpectation = expectation(description: "The expiration handler is called.")
        factory.notifyWhenAllBackgroundActivitiesEnd {
            expirationExpectation.fulfill()
        }

        // WHEN
        simulateApplicationDidEnterBackground()

        // THEN
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }

    func testItDoesNotEndActivities_WhenApplicationComesToTheForeground() {
        // GIVEN
        let _ = factory.startBackgroundActivity(withName: "Activity 1")!
        factory.notifyWhenAllBackgroundActivitiesEnd {
            XCTFail()
        }

        // WHEN
        simulateApplicationDidEnterBackground()
        simulateApplicationWillEnterForeground()
        // force a wait
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "The expiration handler was not called.")], timeout: 3.0)

        // THEN
        XCTAssertNil(factory.backgroundTaskTimer)
        XCTAssertTrue(factory.isActive)
        XCTAssertFalse(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 1)
    }

    func testItEndsBackgroundTaskTimer_WhenAllBackgroundActivitiesAreEnded() {
        // GIVEN
        let activity = factory.startBackgroundActivity(withName: "Activity 1")!

        // WHEN
        simulateApplicationDidEnterBackground()
        factory.endBackgroundActivity(activity)

        // THEN
        XCTAssertNil(factory.backgroundTaskTimer)
        XCTAssertFalse(factory.isActive)
        XCTAssertTrue(factory.activities.isEmpty)
        XCTAssertEqual(activityManager.numberOfTasks, 0)
    }

}

// MARK: - Helpers

extension BackgroundActivityFactoryTests {

    private func simulateApplicationDidEnterBackground() {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func simulateApplicationWillEnterForeground() {
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }

}

extension BackgroundActivityFactory {

    @objc func reset() {
        currentBackgroundTask = nil
        activities.removeAll()
        activityManager = nil
        allTasksEndedHandlers = []
        mainQueue = .main
    }

}
