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

@testable import WireDataModel

class SearchUserSnapshotTests: ZMBaseManagedObjectTest {

    var token: Any?

    override func tearDown() {
        self.token = nil
        super.tearDown()
    }

    func testThatItCreatesASnapshotOfAllValues_noUser() {
        // given
        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "Bernd", handle: "dasBrot", accentColor: .brightOrange, remoteIdentifier: UUID())

        // when
        let sut = SearchUserSnapshot(searchUser: searchUser, managedObjectContext: self.uiMOC)

        // then
        XCTAssertEqual(searchUser.completeImageData, sut.snapshotValues[ #keyPath(ZMSearchUser.completeImageData)] as? Data)
        XCTAssertEqual(searchUser.previewImageData, sut.snapshotValues[ #keyPath(ZMSearchUser.previewImageData)] as? Data)
        XCTAssertEqual(searchUser.user, sut.snapshotValues[ #keyPath(ZMSearchUser.user)] as? ZMUser)
        XCTAssertEqual(searchUser.isConnected, sut.snapshotValues[ #keyPath(ZMSearchUser.isConnected)] as? Bool)
        XCTAssertEqual(searchUser.isPendingApprovalByOtherUser, sut.snapshotValues[ #keyPath(ZMSearchUser.isPendingApprovalByOtherUser)] as? Bool)
    }

    func testThatItCreatesASnapshotOfAllValues_withUser() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()
        user.setImage(data: verySmallJPEGData(), size: .preview)
        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "", handle: "", accentColor: .undefined, remoteIdentifier: UUID(), user: user)

        // when
        let sut = SearchUserSnapshot(searchUser: searchUser, managedObjectContext: self.uiMOC)

        // then
        XCTAssertEqual(searchUser.completeImageData, sut.snapshotValues[ #keyPath(ZMSearchUser.completeImageData)] as? Data)
        XCTAssertEqual(searchUser.previewImageData, sut.snapshotValues[ #keyPath(ZMSearchUser.previewImageData)] as? Data)
        XCTAssertEqual(searchUser.user, sut.snapshotValues[ #keyPath(ZMSearchUser.user)] as? ZMUser)
        XCTAssertEqual(searchUser.isConnected, sut.snapshotValues[ #keyPath(ZMSearchUser.isConnected)] as? Bool)
        XCTAssertEqual(searchUser.isPendingApprovalByOtherUser, sut.snapshotValues[ #keyPath(ZMSearchUser.isPendingApprovalByOtherUser)] as? Bool)
    }

    func testThatItPostsANotificationWhenUserImageChanged() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "", handle: "", accentColor: .undefined, remoteIdentifier: UUID(), user: user)
        let sut = SearchUserSnapshot(searchUser: searchUser, managedObjectContext: self.uiMOC)

        // expect
        let expectation = self.expectation(description: "notified")
        self.token = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: self.uiMOC.notificationContext,
            object: searchUser
        ) { note in
            guard let changeInfo = note.changeInfo as? UserChangeInfo else { return }
            XCTAssertTrue(changeInfo.imageSmallProfileDataChanged)
            expectation.fulfill()
        }

        // when
        user.previewProfileAssetIdentifier = "123"
        uiMOC.zm_userImageCache.setUserImage(user, imageData: verySmallJPEGData(), size: .preview)

        sut.updateAndNotify()

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(searchUser.previewImageData, sut.snapshotValues[ #keyPath(ZMSearchUser.previewImageData)] as? Data)
    }

    func testThatItPostsANotificationWhenConnectionChanged() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "", handle: "", accentColor: .undefined, remoteIdentifier: UUID(), user: user)
        let sut = SearchUserSnapshot(searchUser: searchUser, managedObjectContext: self.uiMOC)

        // expect
        let expectation = self.expectation(description: "notified")
        self.token = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: self.uiMOC.notificationContext,
            object: searchUser
        ) { note in
            guard let changeInfo = note.changeInfo as? UserChangeInfo else { return }
            XCTAssertTrue(changeInfo.connectionStateChanged)
            expectation.fulfill()
        }

        // when
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = user
        connection.status = .accepted
        sut.updateAndNotify()

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(searchUser.isConnected, sut.snapshotValues[ #keyPath(ZMSearchUser.isConnected)] as? Bool)
    }

    func testThatItPostsANotificationWhenPendingApprovalChanged() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = user
        connection.status = .pending

        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "", handle: "", accentColor: .undefined, remoteIdentifier: UUID(), user: user)
        let sut = SearchUserSnapshot(searchUser: searchUser, managedObjectContext: self.uiMOC)

        // expect
        let expectation = self.expectation(description: "notified")
        self.token = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: self.uiMOC.notificationContext,
            object: searchUser
        ) { note in
            guard let changeInfo = note.changeInfo as? UserChangeInfo else { return }
            XCTAssertTrue(changeInfo.connectionStateChanged)
            expectation.fulfill()
        }

        // when
        connection.status = .accepted
        sut.updateAndNotify()

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(searchUser.isConnected, sut.snapshotValues[ #keyPath(ZMSearchUser.isConnected)] as? Bool)
        XCTAssertEqual(searchUser.isPendingApprovalByOtherUser, sut.snapshotValues[ #keyPath(ZMSearchUser.isPendingApprovalByOtherUser)] as? Bool)
    }

    func testThatItPostsANotificationWhenTheUserIsAdded() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "Bernd", handle: "dasBrot", accentColor: .brightOrange, remoteIdentifier: UUID())
        let sut = SearchUserSnapshot(searchUser: searchUser, managedObjectContext: self.uiMOC)

        // expect
        let expectation = self.expectation(description: "notified")
        self.token = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: self.uiMOC.notificationContext,
            object: searchUser
        ) { _ in
            expectation.fulfill()
        }

        // when
        searchUser.setValue(user, forKey: "user") // this is done internally
        sut.updateAndNotify()

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(searchUser.isConnected, sut.snapshotValues[ #keyPath(ZMSearchUser.isConnected)] as? Bool)
        XCTAssertEqual(searchUser.isPendingApprovalByOtherUser, sut.snapshotValues[ #keyPath(ZMSearchUser.isPendingApprovalByOtherUser)] as? Bool)
    }
}

class SearchUserObserverCenterTests: ModelObjectsTests {

    var sut: SearchUserObserverCenter!

    override func setUp() {
        super.setUp()
        sut = SearchUserObserverCenter(managedObjectContext: self.uiMOC)
        uiMOC.userInfo[NSManagedObjectContext.SearchUserObserverCenterKey] = sut
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItDeallocates() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "", handle: "", accentColor: .undefined, remoteIdentifier: UUID(), user: user)
        sut.addSearchUser(searchUser)

        // when
        weak var observerCenter = sut
        sut = nil
        uiMOC.userInfo.removeObject(forKey: NSManagedObjectContext.SearchUserObserverCenterKey)

        // then
        XCTAssertNil(observerCenter)
    }

    func testThatItAddsASnapshot() {
        // given
        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "Bernd", handle: "dasBrot", accentColor: .brightOrange, remoteIdentifier: UUID())
        XCTAssertEqual(sut.snapshots.count, 0)

        // when
        sut.addSearchUser(searchUser)

        // then
        XCTAssertEqual(sut.snapshots.count, 1)
    }

    func testThatItRemovesAllSnapshotsOnReset() {
        // given
        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "Bernd", handle: "dasBrot", accentColor: .brightOrange, remoteIdentifier: UUID())
        sut.addSearchUser(searchUser)
        XCTAssertEqual(sut.snapshots.count, 1)

        // when
        sut.reset()

        // then
        XCTAssertEqual(sut.snapshots.count, 0)
    }

    func testThatItForwardsUserChangeInfosToTheSnapshot() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "", handle: "", accentColor: .undefined, remoteIdentifier: nil, user: user)
        sut.addSearchUser(searchUser)

        // expect
        let expectation = self.expectation(description: "notified")
        let token: Any? = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: self.uiMOC.notificationContext,
            object: searchUser
        ) { _ in
            expectation.fulfill()
        }

        withExtendedLifetime(token) { () -> Void in
            // when
            user.name = "Horst"
            let changeInfo = UserChangeInfo(object: user)
            changeInfo.changedKeys = Set(["name"])
            sut.objectsDidChange(changes: [ZMUser.classIdentifier: [changeInfo]])

            // then
            XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItForwardCallsForUserUpdatesToTheSnapshot() {
        // given
        let searchUser = ZMSearchUser(contextProvider: coreDataStack, name: "Bernd", handle: "dasBrot", accentColor: .brightOrange, remoteIdentifier: UUID())
        sut.addSearchUser(searchUser)

        // expect
        let expectation = self.expectation(description: "notified")
        let token = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: self.uiMOC.notificationContext,
            object: searchUser
        ) { note in
            guard let changeInfo = note.changeInfo as? UserChangeInfo else { return }
            XCTAssertTrue(changeInfo.imageMediumDataChanged)
            expectation.fulfill()
        }

        withExtendedLifetime(token) { () -> Void in
            // when
            searchUser.updateImageData(for: .complete, imageData: verySmallJPEGData())

            // then
            XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}
