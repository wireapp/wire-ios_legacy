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
import WireDataModel

extension SearchTests: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        userNotifications.append(changeInfo)
    }

}

class SearchTests: IntegrationTest {

    var userNotifications: [UserChangeInfo] = []

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    override func tearDown() {
        userNotifications.removeAll()

        super.tearDown()
    }

    // MARK: Connections

    func testThatItConnectsToAUserInASearchResult() {
        // given
        let userName = "JohnnyMnemonic"
        var user: MockUser?

        mockTransportSession.performRemoteChanges { (changes) in
            user = changes.insertUser(withName: userName)
            user?.email = "johnny@example.com"
            user?.phone = ""
        }

        XCTAssertTrue(login())

        // when
        searchAndConnectToUser(withName: userName, searchQuery: "Johnny")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let newUser = self.user(for: user!) else { XCTFail(); return }
        guard let oneToOneConversation = newUser.oneToOneConversation else { XCTFail(); return }
        XCTAssertEqual(newUser.name, userName)
        XCTAssertNotNil(newUser.oneToOneConversation)
        XCTAssertFalse(newUser.isConnected)
        XCTAssertTrue(newUser.isPendingApprovalByOtherUser)

        // remote user accepts connection
        mockTransportSession.performRemoteChanges { (changes) in
            changes.remotelyAcceptConnection(to: user!)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(newUser.isConnected)
        XCTAssertTrue(oneToOneConversation.localParticipants.contains(newUser))
    }

    func testThatTheSelfUserCanAcceptAConnectionRequest() {
        // given
        let userName = "JohnnyMnemonic"
        var user: MockUser?
        let remoteIdentifier = UUID.create()

        mockTransportSession.performRemoteChanges { (changes) in
            user = changes.insertUser(withName: userName)
            user?.email = "johnny@example.com"
            user?.phone = ""
            user?.identifier = remoteIdentifier.transportString()

            let connection = changes.createConnectionRequest(from: self.selfUser, to: user!, message: "Holo")
            connection.status = "pending"

        }

        XCTAssertTrue(login())

        let pendingConnections = ZMConversationList.pendingConnectionConversations(inUserSession: userSession!)
        XCTAssertEqual(pendingConnections.count, 1)
    }

    func testThatItNotifiesObserversWhenTheConnectionStatusChanges_InsertedUser() {
        // given
        let userName = "JohnnyMnemonic"
        var user: MockUser?

        mockTransportSession.performRemoteChanges { (changes) in
            user = changes.insertUser(withName: userName)
            user?.email = "johnny@example.com"
            user?.phone = ""
        }

        XCTAssertTrue(login())

        // find user
        guard let searchUser = searchForDirectoryUser(withName: userName, searchQuery: "Johnny") else { XCTFail(); return }

        // then
        var token = UserChangeInfo.add(observer: self, for: searchUser, in: userSession!)
        XCTAssertNotNil(token)
        XCTAssertNil(searchUser.user)
        XCTAssertEqual(userNotifications.count, 0)

        // connect
        connect(withUser: searchUser)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userNotifications.count, 1)
        guard let userChangeInfo = userNotifications.first else { XCTFail(); return }
        XCTAssertTrue(userChangeInfo.user === searchUser)
        XCTAssertTrue(userChangeInfo.connectionStateChanged)
        token = nil
    }

    func testThatItNotifiesObserversWhenTheConnectionStatusChanges_LocalUser() {
        // given
        let userName = "JohnnyMnemonic"
        var user: MockUser?

        mockTransportSession.performRemoteChanges { (changes) in
            user = changes.insertUser(withName: userName)
            user?.email = "johnny@example.com"
            user?.phone = ""

            self.groupConversation.addUsers(by: self.selfUser, addedUsers: [user!])
        }

        XCTAssertTrue(login())

        // find user
        guard let searchUser = searchForDirectoryUser(withName: userName, searchQuery: "Johnny") else { XCTFail(); return }

        // then
        var token = UserChangeInfo.add(observer: self, for: searchUser, in: userSession!)
        XCTAssertNotNil(token)
        XCTAssertNotNil(searchUser.user)
        XCTAssertEqual(userNotifications.count, 0)

        // connect
        connect(withUser: searchUser)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userNotifications.count, 1)
        guard let userChangeInfo = userNotifications.first else { XCTFail(); return }
        XCTAssertTrue(userChangeInfo.user === searchUser)
        XCTAssertTrue(userChangeInfo.connectionStateChanged)
        token = nil
    }

    // MARK: Profile Images

    func testThatItReturnsTheProfileImageForAConnectedSearchUser() {

        // given
        var profileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            profileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user1.previewProfileAssetIdentifier!)?.data
            userName = self.user1.name
        }

        XCTAssertTrue(login())
        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let user = searchForConnectedUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }

        // when
        user.requestPreviewProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(user.imageSmallProfileData, profileImageData)
    }

    func testThatItReturnsTheProfileImageForAnUnconnectedSearchUser() {
        // given
        var profileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            profileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user4.previewProfileAssetIdentifier!)?.data
            userName = self.user4.name
        }

        XCTAssertTrue(login())
        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }

        // when
        searchUser.requestPreviewProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(searchUser.previewImageData, profileImageData)
    }

    func testThatItReturnsNoImageIfTheUnconnectedSearchUserHasNoImage() {
        // given
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            userName = self.user5.name
        }

        XCTAssertTrue(login())

        // when
        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(searchUser.previewImageData)
    }

    func testThatItNotifiesWhenANewImageIsAvailableForAnUnconnectedSearchUser() {
        // given
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            userName = self.user4.name
        }

        XCTAssertTrue(login())

        // delay mock transport session response
        let semaphore = DispatchSemaphore(value: 0)
        mockTransportSession.responseGeneratorBlock = { (request) in
            if request.path.hasPrefix("/asset") {
                semaphore.wait()
            }

            return nil
        }

        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
        searchUser.requestPreviewProfileImage()
        var token = UserChangeInfo.add(observer: self, for: searchUser, in: userSession!)
        XCTAssertNotNil(token)

        // when
        semaphore.signal()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userNotifications.count, 1)
        guard let userChangeInfo = userNotifications.first else { XCTFail(); return }
        XCTAssertTrue(userChangeInfo.user === searchUser)
        XCTAssertTrue(userChangeInfo.imageSmallProfileDataChanged)
        token = nil
    }

    func testThatItRefetchesTheSearchUserIfItGotEvictedFromTheCache() {
        // given
        var profileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            profileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user4.completeProfileAssetIdentifier!)?.data
            userName = self.user4.name
        }

        XCTAssertTrue(login())

        // first search
        do {
            guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
            guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            searchUser.requestCompleteProfileImage()
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(searchUser.completeImageData, profileImageData)
        }

        // clear the cache
        userSession?.managedObjectContext.zm_searchUserCache?.removeAllObjects()

        // second search
        do {
            guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
            guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            searchUser.requestCompleteProfileImage()
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(searchUser.completeImageData, profileImageData)
        }
    }

    func testThatItNotifiesWhenANewMediumImageIsAvailableForAnUnconnectedSearchUser() {
        // given
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            userName = self.user4.name
        }

        XCTAssertTrue(login())

        // delay mock transport session response
        let semaphore = DispatchSemaphore(value: 0)
        var hasRun = false
        mockTransportSession.responseGeneratorBlock = { (request) in
            if request.path.hasPrefix("/asset") && !hasRun {
                hasRun = true
                semaphore.wait()
            }

            return nil
        }

        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
        searchUser.requestPreviewProfileImage()
        var token = UserChangeInfo.add(observer: self, for: searchUser, in: userSession!)
        XCTAssertNotNil(token)

        // when small profile image response arrives
        semaphore.signal()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userNotifications.count, 1)

        // when requesting medium
        searchUser.requestCompleteProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userNotifications.count, 2)
        guard let userChangeInfo = userNotifications.last else { XCTFail(); return }
        XCTAssertTrue(userChangeInfo.user === searchUser)
        XCTAssertTrue(userChangeInfo.imageMediumDataChanged)

        token = nil
    }

    // MARK: V3 Profile Assets

    func testThatItDownloadsV3PreviewAsset_ConnectedUser() {
        // given
        var profileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            profileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user1.previewProfileAssetIdentifier!)?.data
            userName = self.user1.name
        }

        XCTAssertTrue(login())
        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let user = searchForConnectedUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }

        // when
        mockTransportSession.resetReceivedRequests()
        user.requestPreviewProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(user.imageSmallProfileData, profileImageData)

        let requests = mockTransportSession.receivedRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.path, "/assets/v3/\(user1.previewProfileAssetIdentifier!)")
        XCTAssertEqual(requests.first?.method, .methodGET)
    }

    func testThatItDownloadsV3PreviewAssetWhenOnlyV3AssetsArePrensentInSearchUserResponse_UnconnectedUser() {
        // given
        var profileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (_) in
            profileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user4.previewProfileAssetIdentifier!)?.data
            userName = self.user4.name
        }

        XCTAssertTrue(login())
        mockTransportSession.resetReceivedRequests()

        // when
        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        searchUser.requestPreviewProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(searchUser.previewImageData, profileImageData)

        let requests = mockTransportSession.receivedRequests()
        XCTAssertEqual(requests.count, 4)
        XCTAssertEqual(requests[3].path, "/assets/v3/\(user4.previewProfileAssetIdentifier!)")
        XCTAssertEqual(requests[3].method, .methodGET)
    }

    func testThatItDownloadsMediumAssetForSearchUserWhenAssetAndLegacyIdArePresentUsingV3() {
        verifyThatItDownloadsMediumV3AssetForSearchUser(withLegacyPayloadPresent: true)
    }

    func testThatItDownloadsMediumAssetForSearchUserLegacyIdsAreNotPresentUsingV3() {
        verifyThatItDownloadsMediumV3AssetForSearchUser(withLegacyPayloadPresent: false)
    }

    func verifyThatItDownloadsMediumV3AssetForSearchUser(withLegacyPayloadPresent legacyPayloadPresent: Bool) {
        // given
        var completeProfileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (changes) in
            changes.addV3ProfilePicture(to: self.user4)

            if legacyPayloadPresent {
                self.user4.removeLegacyPictures()
            }

            completeProfileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user4.completeProfileAssetIdentifier!)?.data
            userName = self.user4.name
        }

        XCTAssertTrue(login())

        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
        searchUser.requestPreviewProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        mockTransportSession.resetReceivedRequests()

        // when requesting medium image
        searchUser.requestCompleteProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(searchUser.completeImageData, completeProfileImageData)

        let requests = mockTransportSession.receivedRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].path, "/assets/v3/\(user4.completeProfileAssetIdentifier!)")
        XCTAssertEqual(requests[0].method, .methodGET)
    }

    func testThatItRefetchesTheSearchUserIfTheMediumAssetIDIsNotSet_V3Asset() {
        // given
        var completeProfileImageData: Data?
        var userName: String?

        mockTransportSession.performRemoteChanges { (changes) in
            changes.addV3ProfilePicture(to: self.user4)
            self.user4.removeLegacyPictures()

            completeProfileImageData = MockAsset.init(in: self.mockTransportSession.managedObjectContext, forID: self.user4.completeProfileAssetIdentifier!)?.data
            userName = self.user4.name
        }

        XCTAssertTrue(login())

        guard let searchQuery = userName?.components(separatedBy: " ").last else { XCTFail(); return }
        guard let searchUser = searchForDirectoryUser(withName: userName!, searchQuery: searchQuery) else { XCTFail(); return }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // We reset the requests after having performed the search and fetching the users (in comparison to the other tests).
        mockTransportSession.resetReceivedRequests()

        // when requesting medium image
        searchUser.requestCompleteProfileImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(searchUser.completeImageData, completeProfileImageData)

        let requests = mockTransportSession.receivedRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].path, "/users?ids=\(user4.identifier)")
        XCTAssertEqual(requests[0].method, .methodGET)
        XCTAssertEqual(requests[1].path, "/assets/v3/\(user4.completeProfileAssetIdentifier!)")
        XCTAssertEqual(requests[1].method, .methodGET)
    }

}
