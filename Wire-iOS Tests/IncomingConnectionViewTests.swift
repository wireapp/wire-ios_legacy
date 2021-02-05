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


final class IncomingConnectionViewTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        snapshotBackgroundColor = .white
    }

    func testThatItRendersWithUserName() {
        let user = MockUser.mockUsers().first!
        let sut = IncomingConnectionView(user: user)
        verify(view: sut.layoutForTest())
    }

    func testThatItRendersWithUserName_NoHandle() {
        let user = MockUser.mockUsers().last! // The last user does not have a username
        let sut = IncomingConnectionView(user: user)
        verify(view: sut.layoutForTest())
    }
    
}

fileprivate extension UIView {

    func layoutForTest(in size: CGSize = .init(width: 375, height: 667)) -> UIView {
        let fittingSize = systemLayoutSizeFitting(size)
        frame = CGRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height)
        return self
    }

}
