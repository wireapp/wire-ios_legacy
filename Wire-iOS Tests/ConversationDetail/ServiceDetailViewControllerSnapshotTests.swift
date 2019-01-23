//
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


final class ServiceDetailViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: ServiceDetailViewController!
    var serviceUser: ZMUser!
    var groupConversation: ZMConversation!

    override func setUp() {
        super.setUp()
        serviceUser = createServiceUser()
        groupConversation = createGroupConversation()

        let variant = ServiceDetailVariant(colorScheme: ColorScheme.default.variant, opaque: true)

        sut = ServiceDetailViewController(serviceUser: serviceUser, actionType: .removeService(groupConversation), variant: variant, completion: nil)

        /// TODO: remove this after snapshot is created
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        serviceUser = nil
        groupConversation = nil

        super.tearDown()
    }

    func testForInitState(){
        verify(view: sut.view)
    }

    ///TODO:

    /*
    func testForOptionsForTeamUserInTeamConversation() {
        teamTest {
            selfUser.membership?.setTeamRole(.member)
            groupConversation.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: sut.view)
        }
    }

    func testForOptionsForTeamUserInTeamConversation_Partner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)
            groupConversation.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: sut.view)
        }
    }*/
}
