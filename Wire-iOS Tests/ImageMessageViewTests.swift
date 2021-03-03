//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class ImageMessageViewTests: XCTestCase {
    var sut: ImageMessageView!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()

        mockSelfUser = MockUserType.createSelfUser(name: "Tarja Turunen")
        mockSelfUser.accentColorValue = .vividRed

        sut = ImageMessageView()
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true
    }

    override func tearDown() {
        sut = nil
        mockSelfUser = nil
        super.tearDown()
    }

    func testThatItRendersSmallImage() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.imageMessage(sender: mockSelfUser,
                                                      with: image(inTestBundleNamed: "unsplash_small.jpg"))
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersPortraitImage() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.imageMessage(sender: mockSelfUser,
                                                      with: image(inTestBundleNamed: "unsplash_burger.jpg"))
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersLandscapeImage() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.imageMessage(sender: mockSelfUser,
                                                      with: image(inTestBundleNamed: "unsplash_matterhorn.jpg"))
        // THEN
        verify(matching: sut)
    }

    func testThatItShowsLoadingIndicator() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.pendingImageMessage(sender: mockSelfUser)
        // THEN
        verify(matching: sut)
    }
}
