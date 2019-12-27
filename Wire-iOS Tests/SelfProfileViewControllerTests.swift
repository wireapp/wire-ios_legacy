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

final class SelfProfileViewControllerTests: ZMSnapshotTestCase {
    
    var sut: SelfProfileViewController!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
  
    func testTestForAUserWithNoTeam() {
        createSut(userName: "Tarja Turunen", teamMember: false)

        verify(view: sut.view)
    }

    func testTestForAUserWithALongName() {
        createSut(userName: "Johannes Chrysostomus Wolfgangus Theophilus Mozart")

        verify(view: sut.view)
    }

    private func createSut(userName: String, teamMember: Bool = true) {
        MockUser.mockSelf()?.name = userName
        MockUser.mockSelf()?.isTeamMember = teamMember
        
        sut = SelfProfileViewController(selfUser: MockUser.selfUser, userRightInterfaceType: MockUserRight.self)
        sut.view.backgroundColor = .black
    }
}
