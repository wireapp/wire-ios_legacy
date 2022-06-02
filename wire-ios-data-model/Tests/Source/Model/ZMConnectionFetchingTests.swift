//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class ZMConnectionFetchingTests: DatabaseBaseTest {

    var mocs: CoreDataStack!

    public override func setUp() {
        super.setUp()
        self.mocs = self.createStorageStackAndWaitForCompletion()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 1))
    }

    public override func tearDown() {
        self.mocs = nil
        super.tearDown()
    }

    // MARK: - Fetch using remote identifier

    func testItFetchesEntityByRemoteIdentifier() throws {
        // given
        let uuid = UUID()
        let user = ZMUser.insertNewObject(in: mocs.viewContext)
        user.remoteIdentifier = uuid
        let connection = ZMConnection.insertNewObject(in: mocs.viewContext)
        connection.to = user
        try mocs.viewContext.save()

        // when
        let fetched = ZMConnection.fetch(userID: uuid, domain: nil, in: mocs.viewContext)

        // then
        XCTAssertEqual(connection.objectID, fetched?.objectID)
    }

    func testItDoesntFetchEntityByRemoteIdentifier_WhenRemoteIdentifierDoesntMatch() throws {
        // given
        let uuid = UUID()
        let user = ZMUser.insertNewObject(in: mocs.viewContext)
        user.remoteIdentifier = uuid
        let connection = ZMConnection.insertNewObject(in: mocs.viewContext)
        connection.to = user
        try mocs.viewContext.save()

        // when
        let fetched = ZMConnection.fetch(userID: UUID(), domain: nil, in: mocs.viewContext)

        // then
        XCTAssertNil(fetched)
    }

    // MARK: - Fetch using remote identifier and domain

    func testThatItFetchesEntityByDomain() throws {
        // given
        let domain = "example.com"
        let selfUser = ZMUser.selfUser(in: mocs.viewContext)
        selfUser.domain = domain

        let uuid = UUID()
        let user = ZMUser.insertNewObject(in: mocs.viewContext)
        user.remoteIdentifier = uuid
        user.domain = domain
        let connection = ZMConnection.insertNewObject(in: mocs.viewContext)
        connection.to = user
        try mocs.viewContext.save()

        // when
        let fetched = ZMConnection.fetch(userID: uuid, domain: domain, in: mocs.viewContext)

        // then
        XCTAssertEqual(connection.objectID, fetched?.objectID)
    }

    func testEntityFetching_WhenSearchingForLocalEntity() {
        let localDomain = "example.com"
        let remoteDomain = "remote.com"

        assertEntityFetchingWhen(selfUserDomain: nil,
                                 entityDomain: nil,
                                 searchDomain: nil,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: nil,
                                 searchDomain: nil,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: nil,
                                 entityDomain: localDomain,
                                 searchDomain: nil,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: nil,
                                 searchDomain: localDomain,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: localDomain,
                                 searchDomain: nil,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: nil,
                                 entityDomain: localDomain,
                                 searchDomain: localDomain,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: nil,
                                 searchDomain: remoteDomain,
                                 fetched: false)
    }

    func testEntityFetching_WhenSearchingForRemoteEntity() {
        let localDomain = "example.com"
        let remoteDomain = "remote.com"

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: remoteDomain,
                                 searchDomain: remoteDomain,
                                 fetched: true)

        assertEntityFetchingWhen(selfUserDomain: nil,
                                 entityDomain: localDomain,
                                 searchDomain: remoteDomain,
                                 fetched: false)

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: remoteDomain,
                                 searchDomain: nil,
                                 fetched: false)

        assertEntityFetchingWhen(selfUserDomain: localDomain,
                                 entityDomain: remoteDomain,
                                 searchDomain: localDomain,
                                 fetched: false)
    }

    func assertEntityFetchingWhen(selfUserDomain: String?,
                                  entityDomain: String?,
                                  searchDomain: String?,
                                  fetched: Bool) {

        // given
        let selfUser = ZMUser.selfUser(in: mocs.viewContext)
        selfUser.domain = selfUserDomain

        let uuid = UUID()
        let user = ZMUser.insertNewObject(in: mocs.viewContext)
        user.remoteIdentifier = uuid
        user.domain = entityDomain

        let connection = ZMConnection.insertNewObject(in: mocs.viewContext)
        connection.to = user

        // when
        let fetchedConnection = ZMConnection.fetch(userID: uuid, domain: searchDomain, in: mocs.viewContext)

        // then
        if fetched {
            XCTAssertEqual(connection.objectID, fetchedConnection?.objectID)
        } else {
            XCTAssertNil(fetchedConnection)
        }

        // cleanup
        mocs.viewContext.delete(user)
        mocs.viewContext.delete(connection)
    }

}
