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

final class CanvasViewControllerTests: ZMSnapshotTestCase {
    
    var sut: CanvasViewController!
    
    override func setUp() {
        super.setUp()
        sut = CanvasViewController()

        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForSendButtonEnalbed(){
        sut.sendButton.isEnabled = true
        verify(view: sut.view)
    }

    func testForEmojiKeyboard(){
        sut.emojiButton.sendActions(for: .touchUpInside)
        verify(view: sut.view)
    }
}

