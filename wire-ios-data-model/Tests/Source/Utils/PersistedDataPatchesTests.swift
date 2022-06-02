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
import XCTest
@testable import WireDataModel

// MARK: - Framework comparison
class FrameworkVersionTests: XCTestCase {

    func testThatCorrectVersionsAreParsed() {

        // GIVEN
        let version = FrameworkVersion("13.5.3")

        // THEN
        XCTAssertEqual(version?.major, 13)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 3)
    }

    func testThatCorrectVersionsAreParsedWithZero() {

        // GIVEN
        let version = FrameworkVersion("0.5.0")

        // THEN
        XCTAssertEqual(version?.major, 0)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 0)
    }

    func testThatVersionsWithNoPatchAreParsed() {

        // GIVEN
        let version = FrameworkVersion("2.5")

        // THEN
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 0)
    }

    func testThatVersionsWithNoMinorAreParsed() {

        // GIVEN
        let version = FrameworkVersion("2")

        // THEN
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 0)
        XCTAssertEqual(version?.patch, 0)
    }

    func testThatEmptyVersionIsNotParsed() {

        // GIVEN
        let version = FrameworkVersion("")

        // THEN
        XCTAssertNil(version)
    }

    func testThatVersionWithTooManyIsNotParsed() {

        // GIVEN
        let version = FrameworkVersion("3.4.5.2")

        // THEN
        XCTAssertNil(version)
    }

    func testThatVersionWithTextIsNotParsed() {

        // GIVEN
        let version = FrameworkVersion("3.4.0-alpha")

        // THEN
        XCTAssertNil(version)
    }

    func testEquality() {
        XCTAssertEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.2.3"))
        XCTAssertEqual(FrameworkVersion("0.2.0"), FrameworkVersion("0.2"))
        XCTAssertEqual(FrameworkVersion("0.2"), FrameworkVersion("0.2"))
        XCTAssertNotEqual(FrameworkVersion("1.2.3"), FrameworkVersion("0.2.3"))
        XCTAssertNotEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.3.3"))
        XCTAssertNotEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.2.34"))
    }

    func testComparison() {
        XCTAssertGreaterThan(FrameworkVersion("3.2.1")!, FrameworkVersion("3.2.0")!)
        XCTAssertLessThan(FrameworkVersion("3.2.0")!, FrameworkVersion("3.2.1")!)
        XCTAssertGreaterThan(FrameworkVersion("3.3.1")!, FrameworkVersion("3.2.15")!)
        XCTAssertLessThan(FrameworkVersion("3.2.15")!, FrameworkVersion("3.3.1")!)
        XCTAssertGreaterThan(FrameworkVersion("4.0.0")!, FrameworkVersion("3.2.1")!)
        XCTAssertLessThan(FrameworkVersion("3.2.1")!, FrameworkVersion("4.0.0")!)
        XCTAssertGreaterThan(FrameworkVersion("41.0.0")!, FrameworkVersion("0.0.1")!)
        XCTAssertLessThan(FrameworkVersion("0.0.1")!, FrameworkVersion("41.0.0")!)
    }
}

// MARK: - Test patches
class PersistedDataPatchesTests: ZMBaseManagedObjectTest {

    func testThatItApplyPatchesWhenNoVersion() {

        // GIVEN
        var patchApplied = false
        let patch = PersistedDataPatch(version: "9999.32.32") { (moc) in
            XCTAssertEqual(moc, self.syncMOC)
            patchApplied = true
        }

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            PersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        }

        // THEN
        XCTAssertTrue(patchApplied)
    }

    func testThatItApplyPatchesWhenPreviousVersionIsLesser() {

        // GIVEN
        var patchApplied = false
        let patch = PersistedDataPatch(version: "10000000.32.32") { (moc) in
            XCTAssertEqual(moc, self.syncMOC)
            patchApplied = true
        }
        // this will bump last patched version to current version, which hopefully is less than 10000000.32.32
        self.syncMOC.performGroupedBlockAndWait {
            PersistedDataPatch.applyAll(in: self.syncMOC, patches: [])
        }

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            PersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        }

        // THEN
        XCTAssertTrue(patchApplied)
    }

    func testThatItDoesNotApplyPatchesWhenPreviousVersionIsGreater() {

        // GIVEN
        var patchApplied = false
        let patch = PersistedDataPatch(version: "0.0.1") { (_) in
            XCTFail()
            patchApplied = true
        }
        // this will bump last patched version to current version, which is greater than 0.0.1
        self.syncMOC.performGroupedBlockAndWait {
            PersistedDataPatch.applyAll(in: self.syncMOC, patches: [])
        }

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            PersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        }

        // THEN
        XCTAssertFalse(patchApplied, "Version: \(Bundle(for: ZMUser.self).infoDictionary!["CFBundleShortVersionString"] as! String)")
    }

    func testThatItMigratesClientsSessionIdentifiers() {

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let hardcodedPrekey = "pQABAQUCoQBYIEIir0myj5MJTvs19t585RfVi1dtmL2nJsImTaNXszRwA6EAoQBYIGpa1sQFpCugwFJRfD18d9+TNJN2ZL3H0Mfj/0qZw0ruBPY="
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            let newUser = ZMUser.insertNewObject(in: self.syncMOC)
            newUser.remoteIdentifier = UUID.create()
            let newClient = UserClient.insertNewObject(in: self.syncMOC)
            newClient.user = newUser
            newClient.remoteIdentifier = "aabb2d32ab"

            let otrURL = selfClient.keysStore.cryptoboxDirectory
            XCTAssertTrue(selfClient.establishSessionWithClient(newClient, usingPreKey: hardcodedPrekey))
            self.syncMOC.saveOrRollback()

            let sessionsURL = otrURL.appendingPathComponent("sessions")
            let oldSession = sessionsURL.appendingPathComponent(newClient.remoteIdentifier!)
            let newSession = sessionsURL.appendingPathComponent(newClient.sessionIdentifier!.rawValue)

            XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
            let previousData = try! Data(contentsOf: newSession)

            // move to fake old session
            try! FileManager.default.moveItem(at: newSession, to: oldSession)
            XCTAssertFalse(FileManager.default.fileExists(atPath: newSession.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: oldSession.path))

            // WHEN
            PersistedDataPatch.applyAll(in: self.syncMOC, fromVersion: "0.0.0")

            // THEN
            let readData = try! Data(contentsOf: newSession)
            XCTAssertEqual(readData, previousData)
            XCTAssertFalse(FileManager.default.fileExists(atPath: oldSession.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
        }
    }

    func testThatItMigratesDegradedConversationsWithSecureWithIgnored() {
        // GIVEN
        syncMOC.performGroupedBlockAndWait {
            let notSecureConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            notSecureConversation.conversationType = .oneOnOne
            notSecureConversation.securityLevel = .notSecure
            let secureConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            secureConversation.securityLevel = .secure
            secureConversation.conversationType = .group
            let secureWithIgnoredConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            secureWithIgnoredConversation.securityLevel = .secureWithIgnored
            secureWithIgnoredConversation.conversationType = .oneOnOne

            self.syncMOC.saveOrRollback()

            // WHEN
            PersistedDataPatch.applyAll(in: self.syncMOC, fromVersion: "0.0.0")
            self.syncMOC.saveOrRollback()

            // THEN
            XCTAssertEqual(notSecureConversation.securityLevel, .notSecure)
            XCTAssertEqual(secureConversation.securityLevel, .secure)
            XCTAssertEqual(secureWithIgnoredConversation.securityLevel, .notSecure)
        }
    }

    func testThatItDeletesLocalTeamsAndMembers() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let moc = self.syncMOC
            let conversation = ZMConversation.insertNewObject(in: moc)
            let team = Team.insertNewObject(in: moc)
            let teamConversation = ZMConversation.insertNewObject(in: moc)
            teamConversation.team = team
            let user = ZMUser.insertNewObject(in: moc)
            user.remoteIdentifier = .create()
            let member = Member.getOrCreateMember(for: user, in: team, context: moc)
            XCTAssert(moc.saveOrRollback())

            // when
            PersistedDataPatch.applyAll(in: moc, fromVersion: "0.0.0")
            XCTAssert(moc.saveOrRollback())

            // then
            XCTAssert(team.isZombieObject)
            XCTAssert(member.isZombieObject)
            XCTAssertFalse(conversation.isZombieObject)
            XCTAssertFalse(teamConversation.isZombieObject)

        }
    }

    func testThatItMigratesUserRemoteIdentifiersToTheirMembers() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let moc = self.syncMOC
            let userId1 = UUID.create(), userId2 = UUID.create()
            let user1 = ZMUser.insertNewObject(in: moc), user2 = ZMUser.insertNewObject(in: moc)
            user1.remoteIdentifier = userId1
            user2.remoteIdentifier = userId2
            let team = Team.insertNewObject(in: moc)

            let member1User1 = Member.getOrCreateMember(for: user1, in: team, context: moc)
            let member2User1 = Member.getOrCreateMember(for: user1, in: team, context: moc)
            let member1User2 = Member.getOrCreateMember(for: user2, in: team, context: moc)
            XCTAssert(moc.saveOrRollback())

            // when
            PersistedDataPatch.applyAll(in: moc, fromVersion: "62.0.0")
            XCTAssert(moc.saveOrRollback())

            // then
            XCTAssertEqual(member1User1.remoteIdentifier, user1.remoteIdentifier)
            XCTAssertEqual(member2User1.remoteIdentifier, user1.remoteIdentifier)
            XCTAssertEqual(member1User2.remoteIdentifier, user2.remoteIdentifier)
        }
    }
}
