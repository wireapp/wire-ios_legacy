//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class ConversationTests_Federation: ZMConversationTestsBase {
    var sut: ZMConversation!
    var user: ZMUser!

    override func setUp() {
        super.setUp()
        sut = createConversation(in: uiMOC)
        user = createUser(in: uiMOC)
    }

    override func tearDown() {
        sut = nil
        user = nil
        super.tearDown()
    }

    func testThatIsFederatingReturnsTrue_WhenDomainsAreDifferent() {
        // Given
        sut.domain = UUID().transportString()
        user.domain = UUID().transportString()

        // When / Then
        XCTAssertTrue(sut.isFederating(with: user))
    }

    func testThatIsFederatingReturnsFalse_WhenDomainsAreTheSame() {
        // Given
        let domain = UUID().transportString()
        sut.domain = domain
        user.domain = domain

        // When / Then
        XCTAssertFalse(sut.isFederating(with: user))
    }

    func testThatIsFederatingReturnsFalse_WhenConversationDomainIsNil() {
        // Given
        sut.domain = nil
        user.domain = UUID().transportString()

        // When / Then
        XCTAssertFalse(sut.isFederating(with: user))
    }

    func testThatIsFederatingReturnsFalse_WhenUserDomainIsNil() {
        // Given
        sut.domain = UUID().transportString()
        user.domain = nil

        // When / Then
        XCTAssertFalse(sut.isFederating(with: user))
    }
}
