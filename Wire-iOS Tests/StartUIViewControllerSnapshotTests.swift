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

final class StartUIViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: StartUIViewController!
    var mockAddressBookHelper: MockAddressBookHelper!
    var mockSelfUser: SwiftMockUser!

    override func setUp() {
        super.setUp()
        
        mockSelfUser = SwiftMockUser()
        mockAddressBookHelper = MockAddressBookHelper()
    }

    override func tearDown() {
        sut = nil
        mockAddressBookHelper = nil
        mockSelfUser = nil
        
        super.tearDown()
    }

    func setupSut() {
        sut = StartUIViewController(addressBookHelperType: MockAddressBookHelper.self, selfUser: mockSelfUser)
        sut.view.backgroundColor = .black
    }

    func testForWrappedInNavigationViewController() {
        nonTeamTest {
            setupSut()

            let navigationController = UIViewController().wrapInNavigationController(ClearBackgroundNavigationController.self)

            navigationController.pushViewController(sut, animated: false)

            verifyInAllIPhoneSizes(view: navigationController.view)
        }
    }

    func testForNoContact() {
        nonTeamTest {
            setupSut()

            verifyInAllIPhoneSizes(view: sut.view)
        }
    }


    /// has create group and create guest room rows
    func testForNoContactWhenSelfIsTeamMember() {
        teamTest {
            setupSut()

            verifyInAllIPhoneSizes(view: sut.view)
        }
    }

    /// has no create group and create guest room rows, and no group selector tab
    func testForNoContactWhenSelfIsPartner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)

            setupSut()

            verifyInIPhoneSize(view: sut.view)
        }
    }
}
