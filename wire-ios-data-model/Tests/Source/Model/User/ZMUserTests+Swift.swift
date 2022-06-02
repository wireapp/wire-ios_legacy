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

// MARK: - Modified keys for profile picture upload
final class ZMUserTests_Swift: ModelObjectsTests {

    override func tearDown() {
        APIVersion.isFederationEnabled = false
        super.tearDown()
    }

    func testThatSettingUserProfileAssetIdentifiersDirectlyDoesNotMarkAsModified() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)

        // WHEN
        user.previewProfileAssetIdentifier = "foo"
        user.completeProfileAssetIdentifier = "bar"

        // THEN
        XCTAssertFalse(user.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
        XCTAssertFalse(user.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
    }

    func testThatSettingUserProfileAssetIdentifiersMarksKeysAsModified() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)

        // WHEN
        user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: "foo", completeIdentifier: "bar")

        // THEN
        XCTAssert(user.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
        XCTAssert(user.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
    }

    func testThatSettingUserProfileAssetIdentifiersDoNothingForNonSelfUsers() {
        // GIVEN
        let initialPreview = "123456"
        let initialComplete = "987654"
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.previewProfileAssetIdentifier = initialPreview
        user.completeProfileAssetIdentifier = initialComplete

        // WHEN
        user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: "foo", completeIdentifier: "bar")

        // THEN
        XCTAssertEqual(user.previewProfileAssetIdentifier, initialPreview)
        XCTAssertEqual(user.completeProfileAssetIdentifier, initialComplete)
    }

}

// MARK: - AssetV3 response parsing

extension ZMUserTests_Swift {

    func assetPayload(previewId: String, completeId: String) -> NSArray {
        return [
            ["size": "preview", "type": "image", "key": previewId],
            ["size": "complete", "type": "image", "key": completeId]
        ] as NSArray
    }

    func testThatItDoesNotUpdateAssetsWhenThereAreLocalModifications() {
        syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let user = ZMUser.selfUser(in: self.syncMOC)
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: "foo", completeId: "bar")

            // WHEN
            user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: previewId, completeIdentifier: completeId)
            user.updateAssetData(with: payload, authoritative: true)

            // THEN
            XCTAssertEqual(user.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(user.completeProfileAssetIdentifier, completeId)
        }
    }

    func testThatItIgnoreAssetsWithIllegalCharacters() {
        syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let user = ZMUser.selfUser(in: self.syncMOC)
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: "Aa\\u0000\r\n", completeId: "Aa\\u0000\r\n")

            // WHEN
            user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: previewId, completeIdentifier: completeId)
            user.updateAssetData(with: payload, authoritative: true)

            // THEN
            XCTAssertEqual(user.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(user.completeProfileAssetIdentifier, completeId)
        }
    }

    func testThatItRemovesRemoteIdentifiersWhenWeGetEmptyAssets() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = "some"
            user.completeProfileAssetIdentifier = "other"

            // WHEN
            user.updateAssetData(with: NSArray(), authoritative: true)

            // THEN
            XCTAssertNil(user.previewProfileAssetIdentifier)
            XCTAssertNil(user.completeProfileAssetIdentifier)
        }
    }

    func testThatItUpdatesIdentifiersAndRemovesCachedImagesWhenWeGetRemoteIdentifiers() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = "123"
            user.completeProfileAssetIdentifier = "456"
            user.setImage(data: "some".data(using: .utf8), size: .preview)
            user.setImage(data: "other".data(using: .utf8), size: .complete)
            XCTAssertNotNil(user.imageData(for: .preview))
            XCTAssertNotNil(user.imageData(for: .complete))
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: previewId, completeId: completeId)

            // WHEN
            user.updateAssetData(with: payload, authoritative: true)

            // THEN
            XCTAssertEqual(user.previewProfileAssetIdentifier, previewId)
            XCTAssertNil(user.imageData(for: .preview))
            XCTAssertEqual(user.completeProfileAssetIdentifier, completeId)
            XCTAssertNil(user.imageData(for: .complete))
        }
    }

    func testThatItDoesNotRemoveLocalImagesIfRemoteIdentifiersHaveNotChanged() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let previewId = "some"
            let previewData = "some".data(using: .utf8)
            let completeId = "other"
            let completeData = "other".data(using: .utf8)
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = previewId
            user.completeProfileAssetIdentifier = completeId
            user.setImage(data: previewData, size: .preview)
            user.setImage(data: completeData, size: .complete)
            XCTAssertNotNil(user.imageData(for: .preview))
            XCTAssertNotNil(user.imageData(for: .complete))
            let payload = self.assetPayload(previewId: previewId, completeId: completeId)

            // WHEN
            user.updateAssetData(with: payload, authoritative: true)

            // THEN
            XCTAssertEqual(user.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(user.completeProfileAssetIdentifier, completeId)
            XCTAssertEqual(user.imageData(for: .preview), previewData)
            XCTAssertEqual(user.imageData(for: .complete), completeData)
        }
    }

}

// MARK: - AssetV3 filter predicates
extension ZMUserTests_Swift {
    func testThatPreviewImageDownloadFilterPicksUpUser() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.previewImageDownloadFilter
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = "some-identifier"

            // THEN
            XCTAssert(predicate.evaluate(with: user))
        }
    }

    func testThatCompleteImageDownloadFilterPicksUpUser() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.completeProfileAssetIdentifier = "some-identifier"
            user.setImage(data: nil, size: .complete)

            // THEN
            XCTAssert(predicate.evaluate(with: user))
        }
    }

    func testThatCompleteImageDownloadFilterDoesNotPickUpUsersWithoutAssetId() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.completeProfileAssetIdentifier = nil
            user.setImage(data: "foo".data(using: .utf8), size: .complete)

            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }

    func testThatCompleteImageDownloadFilterDoesNotPickUpUsersWithInvalidAssetId() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.completeProfileAssetIdentifier = "not+valid+id"
            user.setImage(data: "foo".data(using: .utf8), size: .complete)

            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }

    func testThatPreviewImageDownloadFilterDoesNotPickUpUsersWithCachedImages() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = "1234"
            user.setImage(data: "foo".data(using: .utf8), size: .preview)

            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }

    func testThatCompleteImageDownloadFilterDoesNotPickUpUsersWithCachedImages() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.completeProfileAssetIdentifier = "1234"
            user.setImage(data: "foo".data(using: .utf8), size: .complete)

            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }
}

// MARK: - AssetV3 request notifications
extension ZMUserTests_Swift {

    func testThatItPostsPreviewRequestNotifications() {
        let noteExpectation = expectation(description: "PreviewAssetFetchNotification should be fired")
        var userObjectId: NSManagedObjectID?

        let token = ManagedObjectObserverToken(name: .userDidRequestPreviewAsset,
                                               managedObjectContext: self.uiMOC) { note in
            let objectId = note.object as? NSManagedObjectID
            XCTAssertNotNil(objectId)
            XCTAssertEqual(objectId, userObjectId)
            noteExpectation.fulfill()
        }

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        userObjectId = user.objectID
        user.requestPreviewProfileImage()

        withExtendedLifetime(token) { () -> Void in
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItPostsCompleteRequestNotifications() {
        let noteExpectation = expectation(description: "CompleteAssetFetchNotification should be fired")
        var userObjectId: NSManagedObjectID?

        let token = ManagedObjectObserverToken(name: .userDidRequestCompleteAsset,
                                               managedObjectContext: self.uiMOC) { note in
            let objectId = note.object as? NSManagedObjectID
            XCTAssertNotNil(objectId)
            XCTAssertEqual(objectId, userObjectId)
            noteExpectation.fulfill()
        }

        let user =  ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        userObjectId = user.objectID
        user.requestCompleteProfileImage()

        withExtendedLifetime(token) { () -> Void in
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

extension ZMUser {

    @discardableResult
    static func insert(in moc: NSManagedObjectContext, id: UUID = .create(), name: String, handle: String? = nil, connectionStatus: ZMConnectionStatus = .accepted) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.remoteIdentifier = id
        user.name = name
        user.handle = handle
        let connection = ZMConnection.insertNewSentConnection(to: user)
        connection.status = connectionStatus

        return user
    }
}

// MARK: - Predicates
extension ZMUserTests_Swift {

    func testPredicateFilteringConnectedUsersByHandle() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "yyy", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)

        let all = NSArray(array: [user1, user2])

        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "yyy")) as! [ZMUser]

        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringConnectedUsersByHandleWithAtSymbol() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "ab", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)

        let all = NSArray(array: [user1, user2])

        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "@ab")) as! [ZMUser]

        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringConnectedUsersByHandlePrefix() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "alonghandle", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)

        let all = NSArray(array: [user1, user2])

        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "alo")) as! [ZMUser]

        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringConnectedUsersStripsDiactricMarks() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Šőmė body", handle: "hand", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)

        let all = NSArray(array: [user1, user2])

        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "some")) as! [ZMUser]

        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringForAllUsers() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "ab", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "no-b", connectionStatus: .accepted)
        let user3 = ZMUser.insert(in: self.uiMOC, name: "Yes body", handle: "yes-b", connectionStatus: .pending)

        let all = NSArray(array: [user1, user2, user3])

        // When
        let users = all.filtered(using: ZMUser.predicateForAllUsers(withSearch: "body")) as! [ZMUser]

        // Then
        XCTAssertEqual(users.count, 3)
        XCTAssertEqual(users, [user1, user2, user3])
    }

}

// MARK: - Filename
extension ZMUserTests_Swift {

    /// check the generated filename matches several critirias and a regex pattern
    ///
    /// - Parameters:
    ///   - pattern: pattern string for regex
    ///   - filename: filename to check
    func checkFilenameIsValid(pattern: String, filename: String) {
        XCTAssertEqual(filename.count, 214)
        XCTAssertTrue(filename.hasPrefix("Some"))
        XCTAssertTrue(filename.contains("body"))

        let regexp = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regexp.matches(in: filename as String, options: [], range: NSRange(location: 0, length: filename.count))

        XCTAssertTrue(matches.count > 0)
    }

    func testFilenameForUser() throws {
        // Given
        let user = ZMUser.insert(in: self.uiMOC, name: "Some body with a very long name and a emoji 🇭🇰 and some Chinese 中文 and some German Fußgängerübergänge")

        // When
        let filename = user.filename()

        // Then
        /// check ends with a date stamp, e.g. -2017-10-24-11.05.43
        let pattern = "^.*[0-9-.]{20,20}$"
        checkFilenameIsValid(pattern: pattern, filename: filename)
    }

    func testFilenameWithSuffixForUser() throws {
        // Given
        let user = ZMUser.insert(in: self.uiMOC, name: "Some body with a very long name and a emoji 🇭🇰 and some Chinese 中文 and some German Fußgängerübergänge")

        // When
        let suffix: String = "-Jellyfish"
        let filename = user.filename(suffix: suffix)

        // Then
        /// check ends with a date stamp and a suffix, e.g. -2017-10-24-11.05.43-Jellyfish
        let pattern = "^.*[0-9-.]{20,20}\(suffix)$"
        checkFilenameIsValid(pattern: pattern, filename: filename)
    }
}

// MARK: - Availability
extension ZMUserTests_Swift {

    func testThatWeCanUpdateAvailabilityFromGenericMessage() {
        // given
        let user = ZMUser.insert(in: self.uiMOC, name: "Foo")
        XCTAssertEqual(user.availability, .none)
        let availability = Availability(.away)
        // when
        user.updateAvailability(from: GenericMessage(content: availability))

        // then
        XCTAssertEqual(user.availability, .away)
    }

    func testThatWeAllowModifyingAvailabilityOnTheSelfUser() {
        // given
        XCTAssertEqual(selfUser.availability, .none)

        // when
        selfUser.availability = .away

        // then
        XCTAssertEqual(selfUser.availability, .away)
    }

    func testThatWeDontAllowModifyingAvailabilityOnOtherUsers() {
        // given
        let user = ZMUser.insert(in: self.uiMOC, name: "Foo")
        XCTAssertEqual(user.availability, .none)

        // when
        user.availability = .away

        // then
        XCTAssertEqual(user.availability, .none)
    }

    func testThatNeedsToNotifyAvailabilityBehaviourChangeDefaultsToNothing() {
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [])
    }

    func testThatNeedsToNotifyAvailabilityBehaviourChangeCanBeUpdated() {
        // given
        selfUser.needsToNotifyAvailabilityBehaviourChange = .alert

        // then
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, .alert)
    }

}

// MARK: - Broadcast Recipients

extension ZMUserTests_Swift {

    func testThatItReturnsAllKnownTeamUsers() {
        // given
        let selfTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfTeam)

        // fellow team members
        createUserAndAddMember(to: selfTeam)
        createUserAndAddMember(to: selfTeam)

        let otherTeam = createTeam(in: uiMOC)

        // other team users but not connected
        createUserAndAddMember(to: otherTeam)
        createUserAndAddMember(to: otherTeam)

        // other team users and connected
        let (connectedTeamUser1, _) = createUserAndAddMember(to: otherTeam)
        let (connectedTeamUser2, _) = createUserAndAddMember(to: otherTeam)

        // non team users but connected
        let connectedUser1 = createUser(in: uiMOC)
        let connectedUser2 = createUser(in: uiMOC)

        let usersToConnect = [connectedUser1, connectedUser2, connectedTeamUser1, connectedTeamUser2]

        for user in usersToConnect {
            let connection = ZMConnection.insertNewSentConnection(to: user)
            connection.status = .accepted
        }

        // when
        let knownTeamUsers = ZMUser.knownTeamUsers(in: uiMOC)

        // then
        XCTAssertEqual(knownTeamUsers, Set([connectedTeamUser1, connectedTeamUser2]))
    }

    func testThatItReturnsOnlyKnownTeamUsersWithAcceptedConnections() {
        // given
        let selfTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfTeam)

        let otherTeam = createTeam(in: uiMOC)

        // other team users with accepted connections
        let (connectedTeamUser1, _) = createUserAndAddMember(to: otherTeam)
        let (connectedTeamUser2, _) = createUserAndAddMember(to: otherTeam)

        let usersToConnect = [connectedTeamUser1, connectedTeamUser2]

        for user in usersToConnect {
            let connection = ZMConnection.insertNewSentConnection(to: user)
            connection.status = .accepted
        }

        // other team users with unaccepted connections
        for connectionStatus in [ZMConnectionStatus.pending, .blocked, .cancelled, .ignored, .sent, .invalid] {
            let (user, _) = createUserAndAddMember(to: otherTeam)
            let connection = ZMConnection.insertNewSentConnection(to: user)
            connection.status = connectionStatus
        }

        // when
        let knownTeamUsers = ZMUser.knownTeamUsers(in: uiMOC)

        // then
        XCTAssertEqual(knownTeamUsers, Set([connectedTeamUser1, connectedTeamUser2]))
    }

    func testThatItReturnsAllKnownTeamMembers() {
        // given
        let selfUserTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfUserTeam)

        let (selfTeamUser1, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser2, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser3, _) = createUserAndAddMember(to: selfUserTeam)

        _ = ZMUser.insert(in: uiMOC, name: "1", handle: "1", connectionStatus: .accepted)

        let otherTeam = createTeam(in: uiMOC)
        let (otherTeamUser, _) = createUserAndAddMember(to: otherTeam)

        createConversation(in: uiMOC, with: [selfUser, selfTeamUser1])
        createConversation(in: uiMOC, with: [selfUser, selfTeamUser2])
        createConversation(in: uiMOC, with: [selfTeamUser2, selfTeamUser3])
        createConversation(in: uiMOC, with: [selfUser, otherTeamUser])

        // when
        let knownTeamMembers = ZMUser.knownTeamMembers(in: uiMOC)

        // then
        XCTAssertEqual(knownTeamMembers, Set([selfTeamUser1, selfTeamUser2]))
    }

    func testThatReturnsExpectedRecipientsForBroadcast_WhenFederationIsDisabled() {
        // given
        let selfUserTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfUserTeam)

        let (selfTeamUser1, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser2, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser3, _) = createUserAndAddMember(to: selfUserTeam)

        let otherTeam = createTeam(in: uiMOC)

        // unconnected other team users
        createUserAndAddMember(to: otherTeam)
        createUserAndAddMember(to: otherTeam)

        let (connectedTeamUser1, _) = createUserAndAddMember(to: otherTeam)
        let (connectedTeamUser2, _) = createUserAndAddMember(to: otherTeam)

        let usersToConnect = [connectedTeamUser1, connectedTeamUser2]

        for user in usersToConnect {
            let connection = ZMConnection.insertNewSentConnection(to: user)
            connection.status = .accepted
        }

        createConversation(in: uiMOC, with: [selfUser, selfTeamUser1])
        createConversation(in: uiMOC, with: [selfUser, selfTeamUser2])
        createConversation(in: uiMOC, with: [selfTeamUser2, selfTeamUser3])
        createConversation(in: uiMOC, with: [selfUser, connectedTeamUser1])

        // when
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: uiMOC, maxCount: 50)

        // then
        XCTAssertEqual(recipients, Set([selfUser, selfTeamUser1, selfTeamUser2, connectedTeamUser1, connectedTeamUser2]))
    }

    func testThatReturnsExpectedRecipientsForBroadcast_WhenFederationIsEnabled() {
        // given
        let selfUserFederatedTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfUserFederatedTeam)

        let selfDomain = UUID().uuidString
        selfUser.domain = selfDomain
        let (selfTeamUser1, _) = createUserAndAddMember(to: selfUserFederatedTeam, with: selfDomain)
        let (selfTeamUser2, _) = createUserAndAddMember(to: selfUserFederatedTeam, with: selfDomain)
        let (selfTeamUser3, _) = createUserAndAddMember(to: selfUserFederatedTeam, with: selfDomain)

        let otherFederatedTeam = createTeam(in: uiMOC)
        let otherDomain = UUID().uuidString

        // unconnected other team users
        createUserAndAddMember(to: otherFederatedTeam, with: otherDomain)
        createUserAndAddMember(to: otherFederatedTeam, with: otherDomain)

        let (connectedTeamUser1, _) = createUserAndAddMember(to: otherFederatedTeam, with: otherDomain)
        let (connectedTeamUser2, _) = createUserAndAddMember(to: otherFederatedTeam, with: otherDomain)

        let usersToConnect = [connectedTeamUser1, connectedTeamUser2]

        for user in usersToConnect {
            let connection = ZMConnection.insertNewSentConnection(to: user)
            connection.status = .accepted
        }

        createConversation(in: uiMOC, with: [selfUser, selfTeamUser1])
        createConversation(in: uiMOC, with: [selfUser, selfTeamUser2])
        createConversation(in: uiMOC, with: [selfTeamUser2, selfTeamUser3])
        createConversation(in: uiMOC, with: [selfUser, connectedTeamUser1])

        // when
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: uiMOC, maxCount: 50)

        // then
        XCTAssertEqual(recipients, Set([selfUser, selfTeamUser1, selfTeamUser2]))
    }

    func testThatItReturnsRecipientsForBroadcastUpToAMaximumCount() {
        // given
        let selfUserTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfUserTeam)

        let (selfTeamUser1, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser2, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser3, _) = createUserAndAddMember(to: selfUserTeam)

        let allRecipients = [
            selfUser!,
            selfTeamUser1,
            selfTeamUser2,
            selfTeamUser3
        ]

        createConversation(in: uiMOC, with: allRecipients)

        // when
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: uiMOC, maxCount: 3)

        // then
        XCTAssertEqual(recipients.count, 3)
    }

    func testThatItPrioritiesTeamMembersOverOtherTeamUsersForBroadcast() {
        // given
        let selfUserTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfUserTeam)

        let (selfTeamUser1, _) = createUserAndAddMember(to: selfUserTeam)
        let (selfTeamUser2, _) = createUserAndAddMember(to: selfUserTeam)

        let otherTeam = createTeam(in: uiMOC)

        let (connectedTeamUser1, _) = createUserAndAddMember(to: otherTeam)
        let (connectedTeamUser2, _) = createUserAndAddMember(to: otherTeam)

        let usersToConnect = [connectedTeamUser1, connectedTeamUser2]

        for user in usersToConnect {
            let connection = ZMConnection.insertNewSentConnection(to: user)
            connection.status = .accepted
        }

        let allRecipients = [
            selfUser!,
            selfTeamUser1,
            selfTeamUser2,
            connectedTeamUser1,
            connectedTeamUser2
        ]

        createConversation(in: uiMOC, with: allRecipients)

        // when
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: uiMOC, maxCount: 3)

        // then
        XCTAssertEqual(recipients, Set([selfUser, selfTeamUser1, selfTeamUser2]))
    }

    func testThatItRecipientsForBroadcastIsDeterministic() {
        // given
        let selfUserTeam = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: selfUserTeam)

        let (teamUser1, _) = createUserAndAddMember(to: selfUserTeam)
        let (teamUser2, _) = createUserAndAddMember(to: selfUserTeam)
        let (teamUser3, _) = createUserAndAddMember(to: selfUserTeam)
        let (teamUser4, _) = createUserAndAddMember(to: selfUserTeam)

        let allRecipients = [
            selfUser!,
            teamUser1,
            teamUser2,
            teamUser3,
            teamUser4
        ]

        createConversation(in: uiMOC, with: allRecipients)

        // when
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: uiMOC, maxCount: 3)

        // then
        let expectedRecipients = allRecipients.sorted {
            $0.remoteIdentifier.transportString() < $1.remoteIdentifier.transportString()
        }.prefix(3)

        XCTAssertEqual(recipients, Set(expectedRecipients))
    }

}

// MARK: - Bot support
extension ZMUserTests_Swift {
    func testThatServiceIdentifierAndProviderIdentifierAreNilByDefault() {
        // GIVEN
        let sut = ZMUser.insertNewObject(in: self.uiMOC)

        // WHEN & THEN
        XCTAssertNil(sut.providerIdentifier)
        XCTAssertNil(sut.serviceIdentifier)
    }
}

// MARK: - Expiration support
extension ZMUserTests_Swift {
    func testIsWirelessUserCalculation_false() {
        // given
        let sut = ZMUser.insertNewObject(in: self.uiMOC)
        // when & then
        XCTAssertFalse(sut.isWirelessUser)
        XCTAssertFalse(sut.isExpired)
        XCTAssertEqual(sut.expiresAfter, 0)
    }

    func testIsWirelessUserCalculation_true_not_expired() {
        // given
        let sut = ZMUser.insertNewObject(in: self.uiMOC)
        sut.expiresAt = Date(timeIntervalSinceNow: 1)
        // when & then
        XCTAssertTrue(sut.isWirelessUser)
        XCTAssertFalse(sut.isExpired)
        XCTAssertEqual(round(sut.expiresAfter), 1)
    }

    func testIsWirelessUserCalculation_true_expired() {
        // given
        let sut = ZMUser.insertNewObject(in: self.uiMOC)
        sut.expiresAt = Date(timeIntervalSinceNow: -1)
        // when & then
        XCTAssertTrue(sut.isWirelessUser)
        XCTAssertTrue(sut.isExpired)
        XCTAssertEqual(round(sut.expiresAfter), 0)
    }
}

// MARK: - Account deletion

extension ZMUserTests_Swift {

    func testThatUserIsRemovedFromAllConversationsWhenAccountIsDeleted() {
        // given
        let sut = createUser(in: uiMOC)
        let conversation1 = createConversation(in: uiMOC)
        conversation1.conversationType = .group
        conversation1.addParticipantAndUpdateConversationState(user: sut, role: nil)

        let conversation2 = createConversation(in: uiMOC)
        conversation2.conversationType = .group
        conversation2.addParticipantAndUpdateConversationState(user: sut, role: nil)

        // when
        sut.markAccountAsDeleted(at: Date())

        // then
        XCTAssertNil(conversation1.participantRoles.first(where: { $0.user == sut })) // FIXME -> It was XCTAssertNotNil
        XCTAssertNil(conversation2.participantRoles.first(where: { $0.user == sut })) // FIXME -> It was XCTAssertNotNil
    }

    func testThatUserIsNotRemovedFromTeamOneToOneConversationsWhenAccountIsDeleted() {
        // given
        let team = createTeam(in: uiMOC)
        let sut = createTeamMember(in: uiMOC, for: team)
        let teamOneToOneConversation = ZMConversation.fetchOrCreateOneToOneTeamConversation(moc: uiMOC, participant: sut, team: team)!
        teamOneToOneConversation.teamRemoteIdentifier = team.remoteIdentifier

        // when
        sut.markAccountAsDeleted(at: Date())

        // then
        XCTAssertTrue(teamOneToOneConversation.localParticipants.contains(sut))
    }

}

// MARK: - Active conversations

extension ZMUserTests_Swift {

    func testActiveConversationsForSelfUser() {
        // given
        let sut = ZMUser.selfUser(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: sut, role: nil)
        let selfConversation = ZMConversation.fetch(with: self.selfUser.remoteIdentifier, in: uiMOC)

        // then
        XCTAssertEqual(sut.activeConversations, [conversation, selfConversation])
    }

    func testActiveConversationsForOtherUser() {
        // given
        let sut = ZMUser.insertNewObject(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: sut, role: nil)

        // then
        XCTAssertEqual(sut.activeConversations, Set(arrayLiteral: conversation))
    }

}

// MARK: - Self user tests
extension ZMUserTests_Swift {
    func testThatItIsPossibleToSetReadReceiptsEnabled() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        // WHEN
        sut.readReceiptsEnabled = true
        // THEN
        XCTAssertEqual(sut.readReceiptsEnabled, true)
    }

    func testThatItIsPossibleToSetReadReceiptsEnabled_andReset() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        // WHEN
        sut.readReceiptsEnabled = true
        // THEN
        XCTAssertEqual(sut.readReceiptsEnabled, true)
        // AND WHEN
        sut.readReceiptsEnabled = false
        // THEN
        XCTAssertEqual(sut.readReceiptsEnabled, false)
    }

    func testThatItUpdatesOtherContextForEnableReadReceipts() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        // WHEN
        sut.readReceiptsEnabled = true
        self.uiMOC.saveOrRollback()

        // THEN

        self.syncMOC.performGroupedBlock {
            let syncSelfUser = ZMUser.selfUser(in: self.syncMOC)

            XCTAssertEqual(syncSelfUser.readReceiptsEnabled, true)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItSetsModifiedKeysForEnableReadReceipts() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        sut.resetLocallyModifiedKeys(Set())

        // WHEN
        sut.readReceiptsEnabled = true

        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(sut.modifiedKeys, Set([ReadReceiptsEnabledKey]))
    }

    func testThatItDoesNotSetModifiedKeysForEnableReadReceipts() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let sut = ZMUser.selfUser(in: self.syncMOC)
            sut.resetLocallyModifiedKeys(Set())

            // WHEN
            sut.readReceiptsEnabled = true
            self.syncMOC.saveOrRollback()

            // THEN
            XCTAssertEqual(sut.modifiedKeys, nil)
        }
    }

    func testThatItSavesValueOfReadReceiptsEnabled() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)
        // WHEN
        user.readReceiptsEnabled = true
        uiMOC.saveOrRollback()
        // THEN
        XCTAssert(user.readReceiptsEnabled)
    }
}

// MARK: - Verifying user

extension ZMUserTests_Swift {

    func testThatUserIsVerified_WhenSelfUserAndUserIsTrusted() {
        // GIVEN
        let user: ZMUser = self.userWithClients(count: 2, trusted: true)
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        XCTAssertTrue(user.isTrusted)
        XCTAssertTrue(selfUser.isTrusted)

        // THEN
        XCTAssertTrue(user.isVerified)
    }

    func testThatUserIsNotVerified_WhenSelfUserIsNotTrustedButUserIsTrusted() {
        // GIVEN
        let user: ZMUser = self.userWithClients(count: 2, trusted: true)
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let selfClient: UserClient? = selfUser.selfClient()

        // WHEN
        let newClient: UserClient = UserClient.insertNewObject(in: self.uiMOC)
        newClient.user = selfUser
        selfClient?.ignoreClient(newClient)

        // THEN
        XCTAssertTrue(user.isTrusted)
        XCTAssertFalse(selfUser.isTrusted)
        XCTAssertFalse(user.isVerified)
    }

}

// MARK: - Connections

extension ZMUserTests_Swift {

    func testThatConnectSendsAConnectToUserAction() {
        // given
        let user = createUser(in: uiMOC)

        // expect
        expectation(forNotification: ConnectToUserAction.notificationName, object: nil)

        // when
        user.connect { (_) in }

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatAcceptSendsAUpdateConnectionAction() {
        // given
        let user = createUser(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)

        // expect
        expectation(forNotification: UpdateConnectionAction.notificationName, object: nil) { (note) -> Bool in
            guard let action = note.userInfo?[UpdateConnectionAction.userInfoKey] as? UpdateConnectionAction else {
                return false
            }

            return action.newStatus == .accepted
        }

        // when
        user.accept { (_) in }

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatBlockSendsAUpdateConnectionAction() {
        // given
        let user = createUser(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)

        // expect
        expectation(forNotification: UpdateConnectionAction.notificationName, object: nil) { (note) -> Bool in
            guard let action = note.userInfo?[UpdateConnectionAction.userInfoKey] as? UpdateConnectionAction else {
                return false
            }

            return action.newStatus == .blocked
        }

        // when
        user.block { (_) in }

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatIgnoreSendsAUpdateConnectionAction() {
        // given
        let user = createUser(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)

        // expect
        expectation(forNotification: UpdateConnectionAction.notificationName, object: nil) { (note) -> Bool in
            guard let action = note.userInfo?[UpdateConnectionAction.userInfoKey] as? UpdateConnectionAction else {
                return false
            }

            return action.newStatus == .ignored
        }

        // when
        user.ignore { (_) in }

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatCancelConnectionRequestSendsAUpdateConnectionAction() {
        // given
        let user = createUser(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)

        // expect
        expectation(forNotification: UpdateConnectionAction.notificationName, object: nil) { (note) -> Bool in
            guard let action = note.userInfo?[UpdateConnectionAction.userInfoKey] as? UpdateConnectionAction else {
                return false
            }

            return action.newStatus == .cancelled
        }

        // when
        user.cancelConnectionRequest { (_) in }

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}

// MARK: - Domain tests
extension ZMUserTests_Swift {
    func testThatItTreatsEmptyDomainAsNil() {
        // given
        let uuid = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            // when
            let created = ZMUser.fetchOrCreate(with: uuid, domain: "", in: self.syncMOC)

            // then
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(nil, created.domain)
        }
    }

    func testThatItIgnoresDomainWhenFederationIsDisabled() {
        // given
        let uuid = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            // when
            APIVersion.isFederationEnabled = false
            let created = ZMUser.fetchOrCreate(with: uuid, domain: "a.com", in: self.syncMOC)

            // then
            XCTAssertNotNil(created)
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(nil, created.domain)
        }
    }

    func testThatItAssignsDomainWhenFederationIsEnabled() {
        // given
        let uuid = UUID.create()
        let domain = "a.com"

        syncMOC.performGroupedBlockAndWait {
            // when
            APIVersion.isFederationEnabled = true
            let created = ZMUser.fetchOrCreate(with: uuid, domain: domain, in: self.syncMOC)

            // then
            XCTAssertNotNil(created)
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(domain, created.domain)
        }
    }
}
