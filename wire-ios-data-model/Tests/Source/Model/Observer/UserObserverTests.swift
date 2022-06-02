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
@testable import WireDataModel

class UserObserverTests: NotificationDispatcherTestBase {

    let UserClientsKey = "clients"

    enum UserInfoChangeKey: String, CaseIterable {
        case name = "nameChanged"
        case accentColor = "accentColorValueChanged"
        case imageMediumData = "imageMediumDataChanged"
        case imageSmallProfileData = "imageSmallProfileDataChanged"
        case profileInfo = "profileInformationChanged"
        case connectionState = "connectionStateChanged"
        case trustLevel = "trustLevelChanged"
        case handle = "handleChanged"
        case teams = "teamsChanged"
        case availability = "availabilityChanged"
        case readReceiptsEnabled = "readReceiptsEnabledChanged"
        case readReceiptsEnabledChangedRemotely = "readReceiptsEnabledChangedRemotelyChanged"
        case richProfile = "richProfileChanged"
        case legalHoldStatus = "legalHoldStatusChanged"
        case isUnderLegalHold = "isUnderLegalHoldChanged"
        case analyticsIdentifier = "analyticsIdentifierChanged"
    }

    let userInfoChangeKeys: [UserInfoChangeKey] = UserInfoChangeKey.allCases

    var userObserver: UserObserver!

    override func setUp() {
        super.setUp()
        userObserver = UserObserver()
    }

    override func tearDown() {
        userObserver = nil
        super.tearDown()
    }
}

extension UserObserverTests {

    func checkThatItNotifiesTheObserverOfAChange(_ user: ZMUser, modifier: (ZMUser) -> Void, expectedChangedField: UserInfoChangeKey) {
        checkThatItNotifiesTheObserverOfAChange(user, modifier: modifier, expectedChangedFields: [expectedChangedField])
    }

    func checkThatItNotifiesTheObserverOfAChange(_ user: ZMUser, modifier: (ZMUser) -> Void, expectedChangedFields: [UserInfoChangeKey]) {

        // given
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.token = UserChangeInfo.add(observer: userObserver, for: user, in: self.uiMOC)

        // when
        modifier(user)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let changeCount = userObserver.notifications.count
        XCTAssertEqual(changeCount, 1)

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(userObserver.notifications.count, changeCount, "Should not have changed further once")

        guard let changes = userObserver.notifications.first else { return }
        changes.checkForExpectedChangeFields(userInfoKeys: Set(userInfoChangeKeys.map {$0.rawValue}),
                                             expectedChangedFields: Set(expectedChangedFields.map {$0.rawValue}))
    }

    func testThatItNotifiesTheObserverOfANameChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "George"
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.name = "Phil"},
                                                     expectedChangedField: .name)

    }

    func testThatItNotifiestheObserverOfMultipleNameChanges() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        self.token = UserChangeInfo.add(observer: userObserver, for: user, in: self.uiMOC)

        // when
        user.name = "Foo"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(userObserver.notifications.count, 1)

        // and when
        user.name = "Bar"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(userObserver.notifications.count, 2)

        // and when
        self.uiMOC.saveOrRollback()
    }

    func testThatItNotifiesTheObserverOfAnAccentColorChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.accentColorValue = ZMAccentColor.strongBlue
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.accentColorValue = ZMAccentColor.softPink },
                                                     expectedChangedField: .accentColor)

    }

    func testThatItNotifiesTheObserverOfAMediumProfileImageChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.remoteIdentifier = UUID.create()
        user.completeProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: verySmallJPEGData(), size: .complete)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.setImage(data: Data(), size: .complete) },
                                                     expectedChangedField: .imageMediumData)
    }

    func testThatItNotifiesTheObserverOfASmallProfileImageChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.remoteIdentifier = UUID.create()
        user.previewProfileAssetIdentifier = UUID.create().transportString()
        user.setImage(data: verySmallJPEGData(), size: .preview)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.setImage(data: Data(), size: .preview) },
                                                     expectedChangedField: .imageSmallProfileData)
    }

    func testThatItNotifiesTheObserverOfAnEmailChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.setEmailAddress("foo@example.com", on: user)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { self.setEmailAddress(nil, on: $0) },
                                                     expectedChangedField: .profileInfo)
    }

    func testThatItNotifiesTheObserverOfAnUsernameChange_fromNil() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        XCTAssertNil(user.handle)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.setValue("handle", forKey: "handle") },
                                                     expectedChangedField: .handle)
    }

    func testThatItNotifiesTheObserverOfAnUsernameChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.setValue("oldHandle", forKey: "handle")
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.setValue("newHandle", forKey: "handle") },
                                                     expectedChangedField: .handle)
    }

    func testThatItNotifiesTheObserverOfAPhoneNumberChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.setPhoneNumber("+99-32312423423", on: user)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { self.setPhoneNumber("+99-0000", on: $0) },
                                                     expectedChangedField: .profileInfo)
    }

    func testThatItNotifiesTheObserverOfAConnectionStateChange() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.connection = ZMConnection.insertNewObject(in: self.uiMOC)
        user.connection!.status = ZMConnectionStatus.pending
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.connection!.status = ZMConnectionStatus.accepted },
                                                     expectedChangedField: .connectionState)
    }

    func testThatItNotifiesTheObserverOfACreatedIncomingConnection() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: {
                                                        $0.connection = ZMConnection.insertNewObject(in: self.uiMOC)
                                                        $0.connection!.status = ZMConnectionStatus.pending
            },
                                                     expectedChangedField: .connectionState)
    }

    func testThatItNotifiesTheObserverOfACreatedOutgoingConnection() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: {
                                                        $0.connection = ZMConnection.insertNewObject(in: self.uiMOC)
                                                        $0.connection!.status = ZMConnectionStatus.sent
            },
                                                     expectedChangedField: .connectionState)
    }

    func testThatItStopsNotifyingAfterUnregisteringTheToken() {

        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.setEmailAddress("foo@example.com", on: user)
        self.uiMOC.saveOrRollback()

        self.token = UserChangeInfo.add(observer: userObserver, for: user, in: self.uiMOC)

        // when
        self.token = nil
        self.setEmailAddress("aaaaa@example.com", on: user)
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(userObserver.notifications.count, 0)
    }

    func testThatItNotifiesUserForClientStartsTrusting() {

        // given
        let user = ZMUser.selfUser(in: self.uiMOC)
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        user.mutableSetValue(forKey: UserClientsKey).add(client)
        otherUser.mutableSetValue(forKey: UserClientsKey).add(otherClient)

        // when
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        self.checkThatItNotifiesTheObserverOfAChange(otherUser,
                                                     modifier: { _ in client.trustClient(otherClient) },
                                                     expectedChangedField: .trustLevel)

        XCTAssertTrue(otherClient.trustedByClients.contains(client))
    }

    func testThatItNotifiesUserForClientStartsIgnoring() {

        // given
        let user = ZMUser.selfUser(in: self.uiMOC)
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        user.mutableSetValue(forKey: UserClientsKey).add(client)
        otherUser.mutableSetValue(forKey: UserClientsKey).add(otherClient)

        // when
        client.trustClient(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        self.checkThatItNotifiesTheObserverOfAChange(otherUser,
                                                     modifier: { _ in client.ignoreClient(otherClient) },
                                                     expectedChangedField: .trustLevel)

        XCTAssertFalse(otherClient.trustedByClients.contains(client))
        XCTAssertTrue(otherClient.ignoredByClients.contains(client))
    }

    func testThatItUpdatesClientObserversWhenClientIsAdded() {

        // given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let selfClient = UserClient.insertNewObject(in: self.uiMOC)
        selfUser.mutableSetValue(forKey: UserClientsKey).add(selfClient)
        self.uiMOC.saveOrRollback()
        self.token = UserChangeInfo.add(observer: userObserver, for: selfUser, in: self.uiMOC)

        // when
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        selfUser.mutableSetValue(forKey: UserClientsKey).add(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let changeInfo = userObserver.notifications.first else { return XCTFail("Should receive a changeInfo for the added client") }
        XCTAssertTrue(changeInfo.clientsChanged)
        XCTAssertTrue(changeInfo.changedKeys.contains(UserClientsKey))
    }

    func testThatItUpdatesClientObserversWhenClientIsRemoved() {

        // given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let selfClient = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        selfUser.mutableSetValue(forKey: UserClientsKey).add(selfClient)
        selfUser.mutableSetValue(forKey: UserClientsKey).add(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssertEqual(selfUser.clients.count, 2)

        self.token = UserChangeInfo.add(observer: userObserver, for: selfUser, in: self.uiMOC)

        // when
        selfUser.mutableSetValue(forKey: UserClientsKey).remove(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let changeInfo = userObserver.notifications.first else { return XCTFail("Should receive a changeInfo for the added client") }
        XCTAssertTrue(changeInfo.clientsChanged)
        XCTAssertTrue(changeInfo.changedKeys.contains(UserClientsKey))
        XCTAssertEqual(selfUser.clients, Set(arrayLiteral: selfClient))
        XCTAssertEqual(selfUser.clients.count, 1)
    }

    func testThatItUpdatesClientObserversWhenClientsAreFaultedAndNewClientIsAdded() {

        // given
        var objectID: NSManagedObjectID!
        var syncMOCUser: ZMUser!

        syncMOC.performGroupedBlockAndWait {
            syncMOCUser = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncMOC.saveOrRollback()
            objectID = syncMOCUser.objectID
            XCTAssertEqual(syncMOCUser.clients.count, 0)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        guard let object = try? uiMOC.existingObject(with: objectID), let uiMOCUser = object as? ZMUser else {
            return XCTFail("Unable to get user with objectID in uiMOC")
        }

        self.token = UserChangeInfo.add(observer: userObserver, for: uiMOCUser, in: self.uiMOC)

        // when adding a new client on the syncMOC
        syncMOC.performGroupedBlockAndWait {
            let client = UserClient.insertNewObject(in: self.syncMOC)
            syncMOCUser.mutableSetValue(forKey: self.UserClientsKey).add(client)
            self.syncMOC.saveOrRollback()
            XCTAssertTrue(syncMOCUser.isFault)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()

        // then we should receive a changeInfo with clientsChanged on the uiMOC
        let changeInfo = userObserver.notifications.first
        XCTAssertEqual(userObserver.notifications.count, 1)
        XCTAssertEqual(changeInfo?.clientsChanged, true)
        XCTAssertEqual(uiMOCUser.clients.count, 1)
    }

    func testThatItUpdatesClientObserversWhenClientsAreFaultedAndNewClientIsAddedSameContext() {

        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        XCTAssertEqual(user.clients.count, 0)
        XCTAssertFalse(user.clients.first?.user?.isFault == .some(true))

        uiMOC.saveOrRollback()
        uiMOC.refresh(user, mergeChanges: true)
        XCTAssertTrue(user.isFault)
        self.token = UserChangeInfo.add(observer: userObserver, for: user, in: self.uiMOC)

        // when
        let client = UserClient.insertNewObject(in: uiMOC)
        user.mutableSetValue(forKey: UserClientsKey).add(client)

        uiMOC.saveOrRollback()
        uiMOC.refresh(user, mergeChanges: true)
        uiMOC.refresh(client, mergeChanges: true)

        XCTAssertTrue(user.isFault)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let changeInfo = userObserver.notifications.first
        XCTAssertEqual(changeInfo?.clientsChanged, true)
        XCTAssertEqual(user.clients.count, 1)
    }

    func testThatItNotifiesTrustChangeForClientsAddedAfterSubscribing() {

        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let selfClient = UserClient.insertNewObject(in: uiMOC)
        selfUser.mutableSetValue(forKey: UserClientsKey).add(selfClient)

        let observedUser = ZMUser.insertNewObject(in: uiMOC)
        let otherClient = UserClient.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.token = UserChangeInfo.add(observer: userObserver, for: observedUser, in: self.uiMOC)

        // when
        observedUser.mutableSetValue(forKey: UserClientsKey).add(otherClient)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userObserver.notifications.count, 1)
        let note: UserChangeInfo = userObserver.notifications.first!
        let clientsChanged: Bool = note.clientsChanged
        XCTAssertEqual(clientsChanged, true)

        // when
        selfClient.trustClient(otherClient)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let userChangeInfos = userObserver.notifications

        XCTAssertEqual(observedUser.clients.count, 1)
        XCTAssertEqual(userChangeInfos.count, 2)
        XCTAssertEqual(userChangeInfos.map { $0.trustLevelChanged }, [false, true])
        XCTAssertEqual(userChangeInfos.map { $0.clientsChanged }, [true, false])
    }

    func testThatItNotifiesAboutAnAddedTeam() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: {
                                                        let team = Team.insertNewObject(in: self.uiMOC)
                                                        let member = Member.insertNewObject(in: self.uiMOC)
                                                        member.user = $0
                                                        member.team = team },
                                                     expectedChangedField: .teams)
    }

    func testThatItNotifiesAboutChangeInAvailability() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.updateAvailability(.away) },
                                                     expectedChangedField: .availability)
    }

    func testThatItNotifiesTheObserverOfReadReceiptsEnabledChanged() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        user.readReceiptsEnabled = false
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.readReceiptsEnabled = true },
                                                     expectedChangedField: .readReceiptsEnabled)
    }

    func testThatItNotifiesTheObserverOfReadReceiptsEnabledChangedRemotelyChanged() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        user.readReceiptsEnabledChangedRemotely = false
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.readReceiptsEnabledChangedRemotely = true },
                                                     expectedChangedField: .readReceiptsEnabledChangedRemotely)
    }

    func testThatItNotifiesTheObserverOfRichProfileChanged() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        let richProfile = [UserRichProfileField(type: "type", value: "value")]

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.richProfile = richProfile },
                                                     expectedChangedField: .richProfile)
    }

    func testThatItNotifiesTheObserverOfLegalHoldStatusChange_Request() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        user.remoteIdentifier = UUID()

        let legalHoldRequest = LegalHoldRequest.mockRequest(for: user)

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.userDidReceiveLegalHoldRequest(legalHoldRequest) },
                                                     expectedChangedField: .legalHoldStatus)

        XCTAssertTrue(user.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItNotifiesTheObserverOfLegalHoldStatusChange_AcceptRequest() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        user.remoteIdentifier = UUID()

        let request = LegalHoldRequest.mockRequest(for: user)
        user.userDidReceiveLegalHoldRequest(request)

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.userDidAcceptLegalHoldRequest(request) },
                                                     expectedChangedField: .legalHoldStatus)

        XCTAssertTrue(user.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItNotifiesTheObserverOfLegalHoldStatusChange_Added() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { _ in UserClient.createMockLegalHoldSelfUserClient(in: uiMOC) },
                                                     expectedChangedFields: [.legalHoldStatus, .isUnderLegalHold])

        XCTAssertTrue(user.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItNotifiesTheObserverOfLegalHoldStatusChange_Removed() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        user.acknowledgeLegalHoldStatus()

        let legalHoldClient = UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)

        let modifier: (ZMUser) -> Void = { _ in
            self.performPretendingUiMocIsSyncMoc {
                legalHoldClient.deleteClientAndEndSession()
            }
        }

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: modifier,
                                                     expectedChangedFields: [.legalHoldStatus, .isUnderLegalHold])

        XCTAssertTrue(user.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItNotifiesTheObserverOfIsUnderLegalHoldChange_DeviceClassIsAssigned() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "123"
        client.user = user

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { _ in client.deviceClass = .legalHold },
                                                     expectedChangedField: .isUnderLegalHold)
    }

    func testThatItNotifiesTheObserverOfAnalyticsIdentifierChange() {
        // given
        let user = ZMUser.selfUser(in: uiMOC)
        user.analyticsIdentifier = "foo"

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
                                                     modifier: { $0.analyticsIdentifier = "bar" },
                                                     expectedChangedField: .analyticsIdentifier)
    }

}
