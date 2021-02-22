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
    var serviceUser: MockServiceUserType!
    var groupConversation: ZMConversation!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()
        serviceUser = .createServiceUser(name: "ServiceUser")
        groupConversation = createGroupConversation()
        mockSelfUser = .createSelfUser(name: "Bob")
    }

    override func tearDown() {
        sut = nil
        serviceUser = nil
        groupConversation = nil
        mockSelfUser = nil

        super.tearDown()
    }

    func createSut() {
        let variant = ServiceDetailVariant(colorScheme: ColorScheme.default.variant, opaque: true)

        sut = ServiceDetailViewController(serviceUser: serviceUser,
                                          actionType: .removeService(groupConversation),
                                          variant: variant,
                                          selfUser: mockSelfUser)
    }

    func testForTeamMemberWrappedInNavigationController() {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = true
            createSut()
            let navigationController = sut.wrapInNavigationController()
            verify(view: navigationController.view)
        }
    }

    func testForTeamPartner() {
        teamTest {
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            mockSelfUser.canRemoveService = false
            createSut()
            verify(view: sut.view)
        }
    }
}
