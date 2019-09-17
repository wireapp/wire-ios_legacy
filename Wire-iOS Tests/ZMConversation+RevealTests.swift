
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class ZMConversationRevealTests: XCTestCase, CoreDataFixtureTestHelper {

    var sut: ZMConversation!
    var coreDataFixture: CoreDataFixture!
    var mockConversation: ZMConversation!
    var mockUserSession: MockZMUserSession!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        mockConversation = createTeamGroupConversation()
        mockUserSession = MockZMUserSession()
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil
        mockUserSession = nil

        coreDataFixture = nil

        super.tearDown()
    }

    func testThatConversationIsUnarchivedAfterReveal() {
        mockConversation.isArchived = true

        let expectation = self.expectation(description: "Wait for conversation is archived")

        mockConversation.revealClearedOrArchived(userSession: mockUserSession, conversationListType: MockConversationList.self) {
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 2, handler: nil)

        XCTAssertFalse(mockConversation.isArchived)
    }
}
