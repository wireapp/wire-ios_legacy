//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography
@testable import Wire


class ProfileHeaderViewTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        recordMode = true
    }

    func testThatItRendersFallbackUserName() {
        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Thomas", style: .noButton)
        let sut = ProfileHeaderView(viewModel: model)
        verify(view: sut!)
    }

    func testThatItRendersUserName() {
        let user = MockUser.mockUsers().first
        let model = ProfileHeaderViewModel(user: user, fallbackName: "", style: .noButton)
        let sut = ProfileHeaderView(viewModel: model)
        verify(view: sut!)
    }

}


