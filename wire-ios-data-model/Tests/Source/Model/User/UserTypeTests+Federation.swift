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

import Foundation
@testable import WireDataModel

class UserTypeTests_Federation: ModelObjectsTests {

    func testThatUsersAreFederating_WhenBelongingToADifferentDomain() {
        // GIVEN
        let user: ZMUser = self.userWithClients(count: 2, trusted: true)
        user.domain = "foo.com"
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.domain = "bar.com"

        // THEN

        XCTAssertTrue(selfUser.isFederating(with: user))
    }

    func testThatUsersUsersAreNotFederating_WhenBelongingToSameDomain() {
        // GIVEN
        let user: ZMUser = self.userWithClients(count: 2, trusted: true)
        user.domain = "foo.com"
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.domain = "foo.com"

        // THEN
        XCTAssertFalse(selfUser.isFederating(with: user))
    }

    func testThatUsersAreNotFederating_WhenDomainIsUnknown() {
        // GIVEN
        let user: ZMUser = self.userWithClients(count: 2, trusted: true)
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.domain = "foo.com"

        // THEN
        XCTAssertFalse(selfUser.isFederating(with: user))
    }

}
