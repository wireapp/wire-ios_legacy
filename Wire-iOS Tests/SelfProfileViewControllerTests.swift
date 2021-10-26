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

final class SelfProfileViewControllerTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    var sut: SelfProfileViewController!
    var selfUser: MockUserType!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        SelfUser.provider = coreDataFixture.selfUserProvider
    }

    override func tearDown() {
        sut = nil
        selfUser = nil
        super.tearDown()
    }

    func testForAUserWithNoTeam() {
        createSut(userName: "Tarja Turunen", teamMember: false)
        verify(view: sut.view)
    }

    func testForAUserWithALongName() {
        createSut(userName: "Johannes Chrysostomus Wolfgangus Theophilus Mozart")
        verify(view: sut.view)
    }

    func testItRequestsToRefreshTeamMetadataIfSelfUserIsTeamMember() {
        createSut(userName: "Tarja Turunen", teamMember: true)
        XCTAssertEqual(selfUser.refreshTeamDataCount, 1)
    }

    func testItDoesNotRequestToRefreshTeamMetadataIfSelfUserIsNotTeamMember() {
        createSut(userName: "Tarja Turunen", teamMember: false)
        XCTAssertEqual(selfUser.refreshTeamDataCount, 0)
    }

    private func createSut(userName: String, teamMember: Bool = true) {
        // prevent app crash when checking Analytics.shared.isOptout
        Analytics.shared = Analytics(optedOut: true)
        selfUser = MockUserType.createSelfUser(name: userName, inTeam: teamMember ? UUID() : nil)
        sut = SelfProfileViewController(selfUser: selfUser, userRightInterfaceType: MockUserRight.self, userSession: MockZMUserSession())
        sut.view.backgroundColor = .black
    }
}
