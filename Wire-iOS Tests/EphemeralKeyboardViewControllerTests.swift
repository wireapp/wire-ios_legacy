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


class EphemeralKeyboardViewControllerTests: ZMSnapshotTestCase {

    var sut: EphemeralKeyboardViewController!
    var conversation: MockConversation!

    override func setUp() {
        super.setUp()
        conversation = MockConversationFactory.mockConversation()
        conversation.messageDestructionTimeout = ZMConversationMessageDestructionTimeout.fiveMinutes.rawValue
        sut = EphemeralKeyboardViewController(conversation: conversation as Any as! ZMConversation)
    }

    func testThatItRendersCorrectInitially() {
        verify(view: sut.prepareForSnapshots())
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
