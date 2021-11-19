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

import Foundation
@testable import Wire
import XCTest

extension UIView {
    func layoutForTest(in size: CGSize = CGSize(width: 320, height: 480)) {
        let fittingSize = self.systemLayoutSizeFitting(size)
        self.frame = CGRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height)
    }
}

final class UserConnectionViewTests: XCTestCase {

    func sutForUser(_ mockUser: MockUserType = SwiftMockLoader.mockUsers().first!) -> UserConnectionView {
        mockUser.isPendingApprovalByOtherUser = true
        mockUser.isPendingApprovalBySelfUser = false
        mockUser.isConnected = false

        let connectionView = UserConnectionView(user: mockUser)
        connectionView.layoutForTest()

        return connectionView
    }

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }

    func testWithUserName() {
        let sut = sutForUser()
        verify(matching: sut)
    }

    func testWithoutUserName() {
        // The last mock user does not have a handle
        let user = SwiftMockLoader.mockUsers().last!
        let sut = sutForUser(user)
        sut.layoutForTest()
        verify(matching: sut)
    }

}
