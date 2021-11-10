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

import SnapshotTesting
import XCTest
@testable import Wire

final class SearchGroupSelectorSnapshotTests: XCTestCase {
    var sut: SearchGroupSelector!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    private func createSut() {
        sut = SearchGroupSelector(style: .light)
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 320))
    }

    func testForInitState_WhenSelfUserCanNotCreateService() {
        // GIVEN
        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
        createSut()

        // WHEN & THEN
        verify(matching: sut)
    }

    func testThatServiceTabExists_WhenSelfUserCanCreateService() {
        // GIVEN
        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        mockSelfUser.canCreateService = true
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)

        createSut()

        // WHEN & THEN
        verify(matching: sut)
    }
}
