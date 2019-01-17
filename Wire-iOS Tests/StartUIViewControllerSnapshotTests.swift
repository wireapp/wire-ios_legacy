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

final class StartUIViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: StartUIViewController!
    var mockMembership: Member!

    override func setUp() {
        super.setUp()
        sut = StartUIViewController()
        sut.view.backgroundColor = .black

        if mockMembership == nil {
            mockMembership = Member.insertNewObject(in: uiMOC)
        }
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForWrappedInNavigationViewController() {
        MockUser.mockSelf().isTeamMember = false

        let navigationController = UIViewController().wrapInNavigationController(ClearBackgroundNavigationController.self)


        navigationController.pushViewController(sut, animated: false)

        verifyInAllIPhoneSizes(view: navigationController.view)
    }

    func testForNoContact() {
        MockUser.mockSelf().isTeamMember = false
        verifyInAllIPhoneSizes(view: sut.view)
    }


    /// has create group and create guest room rows
    func testForNoContactWhenSelfIsTeamMember() {
        MockUser.mockSelf().isTeamMember = true
        mockMembership.permissions = .member
        MockUser.mockSelf().membership = mockMembership

        verifyInAllIPhoneSizes(view: sut.view)
    }

    /// has no create group and create guest room rows
    func testForNoContactWhenSelfIsPartner() {
        MockUser.mockSelf().isTeamMember = true

        mockMembership.permissions = .partner
        MockUser.mockSelf().membership = mockMembership

        verifyInIPhoneSize(view: sut.view)
    }
}
