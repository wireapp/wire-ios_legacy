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

final class SelfProfileViewControllerSnapshotTests: XCTestCase, CoreDataFixtureTestHelper {
    
    var sut: SelfProfileViewController!
    var coreDataFixture: CoreDataFixture!
    
    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
    }
    
    override func tearDown() {
        coreDataFixture = nil
        sut = nil
        super.tearDown()
    }
  
    func testForAUserWithNoTeam() {
        createSut(userName: "Tarja Turunen", teamMember: false)

        verify(matching: sut)
    }

    func testForAUserWithALongName() {
        createSut(userName: "Johannes Chrysostomus Wolfgangus Theophilus Mozart")

        verify(matching: sut)
    }

    func testForSelfClientsAlert() {
        let mockUserClientSet: Set<UserClient> = Set<UserClient>([coreDataFixture.uiMOC.mockUserClient()])
        
        let alert = UIAlertController(forNewSelfClients: mockUserClientSet)
        
        verify(matching: alert)
    }

    private func createSut(userName: String, teamMember: Bool = true) {
        let selfUser = MockSelfUser()
        selfUser.name = userName
        selfUser.isTeamMember = teamMember
        selfUser.accentColorValue = .vividRed
        
        sut = SelfProfileViewController(selfUser: selfUser,
                                        viewer: selfUser,
                                        userRightInterfaceType: MockUserRight.self)
        sut.view.backgroundColor = .black
    }
}

extension MockSelfUser: ValidatorType, ZMEditableUser {
    
    static func validate(name: inout String?) throws -> Bool {
        //no-op
        return true
    }
    
    var phoneNumber: String! {
        //no-op
        return ""
    }
}

extension MockSelfUser : EditableUserReadReceiptsStatus {
    var readReceiptsEnabledChangedRemotely: Bool {
        return false
    }
}

