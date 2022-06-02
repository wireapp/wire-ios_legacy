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

import XCTest
@testable import WireRequestStrategy
import WireTesting
import WireDataModel

class ZMOTRMessageMissingTests: MessagingTestBase {

    var message: ZMOTRMessage!

    override func setUp() {

        super.setUp()
        self.syncMOC.performGroupedBlockAndWait {
            self.message = try! self.groupConversation.appendText(content: "Test message") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        self.message =  nil
        super.tearDown()
    }

    func testThatItInsertsMissingClientsFromUploadResponse() {

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let missingClientIdentifiers = ["aabbccdd", "ddeeff22"]
            let payload = [
                "missing": [
                    self.otherUser.remoteIdentifier!.transportString(): missingClientIdentifiers
                ],
                "deleted": [:],
                "redundant": [:]
            ]

            // WHEN
            _ = self.message.parseUploadResponse(ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue), clientRegistrationDelegate: MockClientRegistrationStatus())
            self.syncMOC.saveOrRollback()

            // THEN
            let allExistingClients = Set(self.otherUser.clients.map { $0.remoteIdentifier! })
            missingClientIdentifiers.forEach {
                XCTAssert(allExistingClients.contains($0))
            }
        }
    }

    func testThatItDeletesClientsFromUploadResponse() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let client1 = UserClient.insertNewObject(in: self.syncMOC)
            client1.remoteIdentifier = "aabbccdd"
            client1.user = self.otherUser
            let client2 = UserClient.insertNewObject(in: self.syncMOC)
            client2.remoteIdentifier = "11223344"
            client2.user = self.otherUser
            let client3 = UserClient.insertNewObject(in: self.syncMOC)
            client3.remoteIdentifier = "abccdeef"
            client3.user = self.otherUser
            self.syncMOC.saveOrRollback()
            XCTAssertEqual(self.otherUser.clients.count, 4)

            let deletedClientsIdentifier = [client1.remoteIdentifier!, client2.remoteIdentifier!]
            let payload = [
                "missing": [:],
                "deleted": [
                    self.otherUser.remoteIdentifier!.transportString(): deletedClientsIdentifier
                ],
                "redundant": [:]
            ]

            // WHEN
            _ = self.message.parseUploadResponse(ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue), clientRegistrationDelegate: MockClientRegistrationStatus())
            self.syncMOC.saveOrRollback()

            // THEN
            let allExistingClients = Set(self.otherUser.clients.map { $0.remoteIdentifier! })
            deletedClientsIdentifier.forEach {
                XCTAssertFalse(allExistingClients.contains($0))
            }
            XCTAssertTrue(allExistingClients.contains(client3.remoteIdentifier!))
        }
    }

    func testThatItMarksConversationToDownloadFromRedundantUploadResponse() {
        // GIVEN
        self.syncMOC.performGroupedAndWait { moc in
            XCTAssertFalse(self.groupConversation.needsToBeUpdatedFromBackend)
            let payload = [
                "missing": [:],
                "deleted": [:],
                "redundant": [
                    self.otherUser.remoteIdentifier!.transportString(): "aabbccdd"
                ]
            ]

            // WHEN
            _ = self.message.parseUploadResponse(ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue), clientRegistrationDelegate: MockClientRegistrationStatus())
            moc.saveOrRollback()

            // THEN
            XCTAssertTrue(self.groupConversation.needsToBeUpdatedFromBackend)
        }
    }

}
