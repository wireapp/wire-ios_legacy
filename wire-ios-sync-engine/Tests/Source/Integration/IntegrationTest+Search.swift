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

import WireMockTransport
import XCTest
import WireTesting

extension IntegrationTest {

    @objc
    public func searchAndConnectToUser(withName name: String, searchQuery: String) {
        createSharedSearchDirectory()

        let searchCompleted = expectation(description: "Search result arrived")
        let request = SearchRequest(query: searchQuery, searchOptions: [.directory])
        let task = sharedSearchDirectory?.perform(request)
        var searchResult: SearchResult?

        task?.onResult { (result, completed) in
            if completed {
                searchResult = result
                searchCompleted.fulfill()
            }
        }

        task?.start()

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(searchResult)

        let searchUser = searchResult?.directory.first
        XCTAssertNotNil(searchUser)
        XCTAssertEqual(searchUser?.name, name)

        searchUser?.connect(completion: {_ in })
    }

    @objc
    public func searchForDirectoryUser(withName name: String, searchQuery: String) -> ZMSearchUser? {
        createSharedSearchDirectory()

        let searchCompleted = expectation(description: "Search result arrived")
        let request = SearchRequest(query: searchQuery, searchOptions: [.directory])
        let task = sharedSearchDirectory?.perform(request)
        var searchResult: SearchResult?

        task?.onResult { (result, completed) in
            if completed {
                searchResult = result
                searchCompleted.fulfill()
            }
        }

        task?.start()

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(searchResult)

        return searchResult?.directory.first
    }

    @objc
    public func searchForConnectedUser(withName name: String, searchQuery: String) -> ZMUser? {
        createSharedSearchDirectory()

        let searchCompleted = expectation(description: "Search result arrived")
        let request = SearchRequest(query: searchQuery, searchOptions: [.contacts])
        let task = sharedSearchDirectory?.perform(request)
        var searchResult: SearchResult?

        task?.onResult { (result, completed) in
            if completed {
                searchResult = result
                searchCompleted.fulfill()
            }
        }

        task?.start()

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(searchResult)

        return searchResult?.contacts.compactMap(\.user).first
    }

    @objc
    public func connect(withUser user: UserType) {
        user.connect(completion: {_ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

}
