////
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

import Foundation
import XCTest

class ZMHotFixTests_Integration: MessagingTest {

    func testThatAllConversationsAreUpdated_198_0_0() {
        var g1: ZMConversation!
        var g2: ZMConversation!
        var g3: ZMConversation!

        syncMOC.performGroupedAndWait { _ in
            // given
            g1 = ZMConversation.insertNewObject(in: self.syncMOC)
            g1.conversationType = .group
            XCTAssertFalse(g1.needsToBeUpdatedFromBackend)

            g2 = ZMConversation.insertNewObject(in: self.syncMOC)
            g2.conversationType = .connection
            g2.team = Team.insertNewObject(in: self.syncMOC)
            XCTAssertFalse(g2.needsToBeUpdatedFromBackend)

            g3 = ZMConversation.insertNewObject(in: self.syncMOC)
            g3.conversationType = .connection
            XCTAssertFalse(g3.needsToBeUpdatedFromBackend)

            self.syncMOC.setPersistentStoreMetadata("147.0", key: "lastSavedVersion")
            let sut = ZMHotFix(syncMOC: self.syncMOC)

            // when
            self.performIgnoringZMLogError {
                sut?.applyPatches(forCurrentVersion: "198.0")
            }
        }

        syncMOC.performGroupedAndWait { _ in
            // then
            XCTAssertTrue(g1.needsToBeUpdatedFromBackend)
            XCTAssertTrue(g2.needsToBeUpdatedFromBackend)
            XCTAssertTrue(g3.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItRemovesPendingConfirmationsForDeletedMessages_54_0_1() {
        var confirmationMessage: ZMClientMessage! = nil
        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("0.1", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(value: true), key: "HasHistory")

            let oneOnOneConversation = ZMConversation(context: self.syncMOC)
            oneOnOneConversation.conversationType = .oneOnOne
            oneOnOneConversation.remoteIdentifier = UUID()

            let otherUser = ZMUser(context: self.syncMOC)
            otherUser.remoteIdentifier = UUID()

            let incomingMessage = try! oneOnOneConversation.appendText(content: "Test") as! ZMClientMessage
            let confirmation = Confirmation(messageId: incomingMessage.nonce!, type: .delivered)

            confirmationMessage = try! oneOnOneConversation.appendClientMessage(with: GenericMessage(content: confirmation), expires: false, hidden: true)

            self.syncMOC.saveOrRollback()

            XCTAssertNotNil(confirmationMessage)
            XCTAssertFalse(confirmationMessage.isDeleted)

            incomingMessage.visibleInConversation = nil
            incomingMessage.hiddenInConversation = oneOnOneConversation

            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "54.0.1")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            self.syncMOC.saveOrRollback()
        }
        syncMOC.performGroupedBlock {
            XCTAssertNil(confirmationMessage.managedObjectContext)
        }
    }

    func testThatItUpdatesManagedByPropertyFromUser_From_235_0_0() {
        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("235.0.0", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(value: true), key: "HasHistory")

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.needsToBeUpdatedFromBackend = false
            self.syncMOC.saveOrRollback()

            XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend)

            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "235.0.1")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertTrue(selfUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItMarksTeamMembersToBeUpdatedFromTheBackend_238_0_0() {
        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("238.0.0", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(value: true), key: "HasHistory")

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = Team.fetchOrCreate(with: UUID(), create: true, in: self.syncMOC, created: nil)!
            let member = Member.getOrCreateMember(for: selfUser, in: team, context: self.syncMOC)
            member.needsToBeUpdatedFromBackend = false

            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "238.0.1")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            ZMUser.selfUser(in: self.syncMOC).team?.members.forEach({ (member) in
                XCTAssertTrue(member.needsToBeUpdatedFromBackend)
            })
        }
    }

    func testThatItMarksLabelsToBeRefetched_280_0_0() {
        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("238.0.0", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(value: true), key: "HasHistory")

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.needsToRefetchLabels = false

            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "280.0.1")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertTrue(selfUser.needsToRefetchLabels)
        }
    }

    func testThatItMarksClientsNeedsToUpdateCapabilities_381_0_0() {
        let selfClient = self.createSelfClient(self.syncMOC)
        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("380.0.0", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(value: true), key: "HasHistory")

            selfClient.needsToUpdateCapabilities = false
            self.syncMOC.saveOrRollback()
            XCTAssertFalse(selfClient.hasLocalModifications(forKey: ZMUserClientNeedsToUpdateCapabilitiesKey))

            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "381.0.1")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            XCTAssertTrue(selfClient.needsToUpdateCapabilities)
            XCTAssertTrue(selfClient.hasLocalModifications(forKey: ZMUserClientNeedsToUpdateCapabilitiesKey))
        }
    }

    func testThatItRefetchesAllUsers_412_3_3() {
        var selfUser: ZMUser!
        var user1: ZMUser!
        var user2: ZMUser!

        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("412.3.2", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(value: true), key: "HasHistory")

            selfUser = ZMUser.selfUser(in: self.syncMOC)
            user1 = ZMUser.insertNewObject(in: self.syncMOC)
            user2 = ZMUser.insertNewObject(in: self.syncMOC)

            selfUser.needsToBeUpdatedFromBackend = false
            user1.needsToBeUpdatedFromBackend = false
            user2.needsToBeUpdatedFromBackend = false

            XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend)
            XCTAssertFalse(user1.needsToBeUpdatedFromBackend)
            XCTAssertFalse(user2.needsToBeUpdatedFromBackend)

            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "412.3.3")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            XCTAssertTrue(selfUser.needsToBeUpdatedFromBackend)
            XCTAssertTrue(user1.needsToBeUpdatedFromBackend)
            XCTAssertTrue(user2.needsToBeUpdatedFromBackend)
        }
    }

    func createSelfClient(_ context: NSManagedObjectContext) -> UserClient {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = UUID().transportString()
        selfClient.user = ZMUser.selfUser(in: context)
        context.saveOrRollback()
        context.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: "PersistedClientId")
        return selfClient
    }
}
