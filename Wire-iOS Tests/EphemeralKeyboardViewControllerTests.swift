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


class EphemeralKeyboardViewControllerTests: CoreDataSnapshotTestCase {

    var sut: EphemeralKeyboardViewController!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        conversation = self.createGroupConversation()
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue.fiveMinutes)
        sut = EphemeralKeyboardViewController(conversation: conversation)
    }

    override func tearDown() {
        conversation = nil
        sut = nil
        super.tearDown()
    }


    func testThatItRendersCorrectInitially() {
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersCorrectIntially_DarkMode() {
        ColorScheme.default.variant = .dark
        verify(view: sut.prepareForSnapshots())
        ColorScheme.default.variant = .light
    }

}

fileprivate extension UIViewController {

    func prepareForSnapshots() -> UIView {
        constrain(view) { view in
            view.height == 290
            view.width == 375
        }

        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()

        view.layer.speed = 0
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view
    }

}
