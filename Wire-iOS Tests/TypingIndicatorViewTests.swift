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

@testable import Wire
import Cartography

class TypingIndicatorViewTests: ZMSnapshotTestCase {

    var sut: TypingIndicatorView!
    
    override func setUp() {
        super.setUp()
        sut = TypingIndicatorView()
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.layer.speed = 0
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testOneTypingUser() {
        sut.typingUsers = Array(MockUser.mockUsers().prefix(1))
        sut.layoutIfNeeded()
        verify(view: sut)
    }
    
    func testTwoTypingUsers() {
        sut.typingUsers = Array(MockUser.mockUsers().prefix(2))
        sut.layoutIfNeeded()
        verify(view: sut)
    }
    
    func testManyTypingUsers() {
        // limit width to test overflow behaviour
        constrain(sut) { typingIndicator in
            typingIndicator.width == 320
        }
        
        sut.typingUsers = Array(MockUser.mockUsers().prefix(5))
        sut.layoutIfNeeded()
        verify(view: sut)
    }
}
