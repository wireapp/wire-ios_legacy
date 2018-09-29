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

import XCTest
@testable import Wire
import WireDataModel

final class ParticipantDeviceCellTests: ZMSnapshotTestCase {

    var sut: ParticipantDeviceCell!
    var user: ZMUser!

    override func setUp() {
        super.setUp()
        sut = ParticipantDeviceCell(style: .default, reuseIdentifier: "reuseIdentifier")
        sut.bounds = CGRect(x: 0, y: 0, width: 320, height: 64)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        user = ZMUser.insertNewObject(in: uiMOC)
    }

    override func tearDown() {
        sut = nil
        user = nil
        super.tearDown()
    }

    func testThatItRendersTheCellUnverifiedFullWidthIdentifierLongerThan_16_Characters() {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "102030405060708090"
        client.user = user
        client.deviceClass = "tablet"
        sut.configure(for: client)
        verify(view: sut.wrapInTableView())
    }

    func testThatItRendersTheCellUnverifiedTruncatedIdentifier() {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "807060504030201"
        client.user = user
        client.deviceClass = "desktop"
        sut.configure(for: client)
        verify(view: sut.wrapInTableView())
    }

    func testThatItRendersTheCellUnverifiedTruncatedIdentifierMultipleCharactersMissing() {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "7060504030201"
        client.user = user
        client.deviceClass = "desktop"
        sut.configure(for: client)
        verify(view: sut.wrapInTableView())
    }

    func testThatItRendersTheCellVerifiedWithLabel() {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "e7b2u9d4s85h1gv0"
        client.user = user
        client.deviceClass = "phone"
        trust(client)
        sut.configure(for: client)
        verify(view: sut.wrapInTableView())
    }

    // MARK: - Helper
    func trust(_ client: UserClient?) {
        let selfClient = UserClient.insertNewObject(in: uiMOC)
        selfClient.remoteIdentifier = "selfClientID"

        let persistableMetadata = "selfClientID" as PersistableInMetadata
        uiMOC.setPersistentStoreMetadata(persistableMetadata, key: ZMPersistedClientIdKey)
        selfClient.user = ZMUser.selfUser(in: uiMOC)
        selfClient.trustClient(client!)
    }
}
