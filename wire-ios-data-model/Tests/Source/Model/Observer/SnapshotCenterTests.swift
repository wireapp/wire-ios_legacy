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

class SnapshotCenterTests: BaseZMMessageTests {

    var sut: SnapshotCenter!

    override func setUp() {
        super.setUp()
        sut = SnapshotCenter(managedObjectContext: uiMOC)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItCreatesSnapshotsOfObjects() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)

        // when
        _ = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        XCTAssertNotNil(sut.snapshots[conv.objectID])
    }

    func testThatItSnapshotsNilValues() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)

        // when
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}

        // then
        let expectedAttributes: [String: NSObject?] = ["userDefinedName": nil,
                                                           "internalEstimatedUnreadCount": 0 as NSObject?,
                                                           "hasUnreadUnsentMessage": 0 as NSObject?,
                                                           "archivedChangedTimestamp": nil,
                                                           "isSelfAnActiveMember": 1 as NSObject?,
                                                           "draftMessageText": nil,
                                                           "modifiedKeys": nil,
                                                           "securityLevel": 0 as NSObject?,
                                                           "lastServerTimeStamp": nil,
                                                           "localMessageDestructionTimeout": 0 as NSObject?,
                                                           "syncedMessageDestructionTimeout": 0 as NSObject?,
                                                           "clearedTimeStamp": nil,
                                                           "needsToBeUpdatedFromBackend": 0 as NSObject?,
                                                           "lastUnreadKnockDate": nil,
                                                           "conversationType": 0 as NSObject?,
                                                           "internalIsArchived": 0 as NSObject?,
                                                           "lastModifiedDate": nil,
                                                           "silencedChangedTimestamp": nil,
                                                           "lastUnreadMissedCallDate": nil,
                                                           "voiceChannel": nil,
                                                           "remoteIdentifier_data": nil,
                                                           "lastReadServerTimeStamp": nil,
                                                           "normalizedUserDefinedName": nil,
                                                           "remoteIdentifier": nil,
                                                           "mutedStatus": 0 as NSObject?]
        let expectedToManyRelationships = ["hiddenMessages": 0,
                                           "participantRoles": 0,
                                           "allMessages": 0,
                                           "labels": 0,
                                           "nonTeamRoles": 0,
                                           "lastServerSyncedActiveParticipants": 0]

        expectedAttributes.forEach {
            XCTAssertEqual(snapshot.attributes[$0] ?? nil, $1)
        }
        XCTAssertEqual(snapshot.toManyRelationships, expectedToManyRelationships)
    }

    func testThatItSnapshotsSetValues() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        conv.conversationType = .group
        conv.userDefinedName = "foo"
        conv.creator = ZMUser.insertNewObject(in: uiMOC)
        performPretendingUiMocIsSyncMoc {
            conv.lastModifiedDate = Date()
            conv.lastServerTimeStamp = Date()
            conv.lastUnreadKnockDate = Date()
            conv.lastUnreadMissedCallDate = Date()
        }
        conv.mutedMessageTypes = .all
        conv.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC))
        try! conv.appendText(content: "foo")
        conv.resetLocallyModifiedKeys(conv.keysThatHaveLocalModifications)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)

        // when
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}

        // then
        let expectedAttributes: [String: NSObject?] = ["userDefinedName": conv.userDefinedName as NSObject?,
                                                         "internalEstimatedUnreadCount": 0 as NSObject?,
                                                         "hasUnreadUnsentMessage": 0 as NSObject?,
                                                         "archivedChangedTimestamp": nil,
                                                         "draftMessageText": nil,
                                                         "modifiedKeys": nil,
                                                         "securityLevel": 0 as NSObject?,
                                                         "lastServerTimeStamp": conv.lastServerTimeStamp as NSObject?,
                                                         "localMessageDestructionTimeout": 0 as NSObject?,
                                                         "syncedMessageDestructionTimeout": 0 as NSObject?,
                                                         "clearedTimeStamp": nil,
                                                         "needsToBeUpdatedFromBackend": 0 as NSObject?,
                                                         "lastUnreadKnockDate": conv.lastUnreadKnockDate as NSObject?,
                                                         "conversationType": conv.conversationType.rawValue as NSObject?,
                                                         "internalIsArchived": 0 as NSObject?,
                                                         "lastModifiedDate": conv.lastModifiedDate as NSObject?,
                                                         "silencedChangedTimestamp": conv.silencedChangedTimestamp as NSObject?,
                                                         "lastUnreadMissedCallDate": conv.lastUnreadMissedCallDate as NSObject?,
                                                         "voiceChannel": nil,
                                                         "remoteIdentifier_data": nil,
                                                         "lastReadServerTimeStamp": conv.lastReadServerTimeStamp as NSObject?,
                                                         "normalizedUserDefinedName": conv.normalizedUserDefinedName as NSObject?,
                                                         "remoteIdentifier": nil,
                                                         "mutedStatus": (MutedMessageOptionValue.all.rawValue) as NSObject?]
        let expectedToManyRelationships = ["hiddenMessages": 0,
                                           "participantRoles": 0,
                                           "allMessages": 1,
                                           "labels": 0,
                                           "nonTeamRoles": 0,
                                           "lastServerSyncedActiveParticipants": 0]

        let expectedToOneRelationships: [String: NSManagedObjectID] =
            ["creator": conv.creator.objectID]

        expectedAttributes.forEach {
            XCTAssertEqual((snapshot.attributes[$0] ?? nil), $1, "values for \($0) don't match")
        }
        XCTAssertEqual(snapshot.toManyRelationships, expectedToManyRelationships)
        XCTAssertEqual(snapshot.toOneRelationships, expectedToOneRelationships)
    }

    func testThatReturnsChangedKeys() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)

        // when
        conv.userDefinedName = "foo"
        let changedKeys = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        XCTAssertEqual(changedKeys.count, 2)
        XCTAssertEqual(changedKeys, Set(["normalizedUserDefinedName", "userDefinedName"]))
    }

    func testThatItUpatesTheSnapshot() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        _ = sut.extractChangedKeysFromSnapshot(for: conv)

        // when
        conv.userDefinedName = "foo"
        _ = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}

        // then
        XCTAssertEqual(snapshot.attributes["userDefinedName"] as? String, "foo")
    }

    func testThatItReturnsAllKeysChangedWhenSnapshotDoesNotExist() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)

        // when
        let changedKeys = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        XCTAssertEqual(changedKeys, Set(conv.entity.attributesByName.keys).union(["hiddenMessages",
                                                                                  "participantRoles",
                                                                                  "allMessages",
                                                                                  "labels",
                                                                                  "nonTeamRoles",
                                                                                  "lastServerSyncedActiveParticipants"]))
    }

    func testThatItUpatesTheSnapshotForParticipantRole() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let user = ZMUser.insertNewObject(in: uiMOC)
        let role1 = Role.insertNewObject(in: uiMOC)
        role1.name = "foo"
        let role2 = Role.insertNewObject(in: uiMOC)
        role2.name = "bar"
        let pr = ParticipantRole.create(managedObjectContext: uiMOC, user: user, conversation: conversation)
        pr.role = role1
        uiMOC.saveOrRollback()
        _ = sut.extractChangedKeysFromSnapshot(for: pr)

        // when
        pr.role = role2
        uiMOC.saveOrRollback()
        let changedKeys = sut.extractChangedKeysFromSnapshot(for: pr)

        // then
        guard let snapshot = sut.snapshots[pr.objectID] else { return XCTFail("did not create snapshot")}

        // then
        XCTAssertEqual(snapshot.toOneRelationships["role"], role2.objectID)
        XCTAssertEqual(changedKeys, Set(["role"]))
    }

}
