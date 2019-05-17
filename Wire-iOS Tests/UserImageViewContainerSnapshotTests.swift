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

final class UserImageViewContainerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: UserImageViewContainer!
    let maxSize = CGFloat(240)
    var mockUser: MockUser!

    override func setUp() {
        super.setUp()

        mockUser = (MockUser.mockUsers()?.first as Any as! MockUser)
        mockUser.profileImage = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForNoUserImageWithoutSession(){
        sut = UserImageViewContainer(size: .big, maxSize: maxSize, yOffset: -8, userSession:nil)
        sut.frame = CGRect(origin: .zero, size: CGSize(width: maxSize, height: maxSize))
        sut.user = mockUser

        verify(view: sut)
    }

    func testForWithUserImage(){
        var mockZMUserSession: MockZMUserSession!
        mockZMUserSession = MockZMUserSession()

        sut = UserImageViewContainer(size: .big, maxSize: maxSize, yOffset: -8, userSession: mockZMUserSession)
        sut.frame = CGRect(origin: .zero, size: CGSize(width: maxSize, height: maxSize))
        sut.user = mockUser

        verify(view: sut)
    }
}
