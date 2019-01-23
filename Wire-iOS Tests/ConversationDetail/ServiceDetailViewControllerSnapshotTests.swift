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
    }
    
    override func tearDown() {
        sut = nil
        serviceUser = nil
        groupConversation = nil

        super.tearDown()
    }

    func createSut() {
        let variant = ServiceDetailVariant(colorScheme: ColorScheme.default.variant, opaque: true)

        sut = ServiceDetailViewController(serviceUser: serviceUser, actionType: .removeService(groupConversation), variant: variant, completion: nil)
    }

    func testForTeamMember() {
        teamTest {
            createSut()
            verify(view: sut.view)
        }
    }

    func testForTeamPartner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)
            createSut()
            verify(view: sut.view)
        }
    }
}
