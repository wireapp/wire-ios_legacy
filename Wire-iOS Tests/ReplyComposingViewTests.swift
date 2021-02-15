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

fileprivate class ReplyComposingViewMockDelegate: NSObject, ReplyComposingViewDelegate {
    var didCancelCalledCount: Int = 0
    func composingViewDidCancel(composingView: ReplyComposingView) {
        didCancelCalledCount = didCancelCalledCount + 1
    }
    
    var composingViewWantsToShowMessage: Int = 0
    func composingViewWantsToShowMessage(composingView: ReplyComposingView, message: ZMConversationMessage) {
        composingViewWantsToShowMessage = composingViewWantsToShowMessage + 1
    }
}

final class ReplyComposingViewTests: XCTestCase {
    func testDeallocation() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")
        self.verifyDeallocation {
            return ReplyComposingView(message: message)
        }
    }
    
    func testThatItCallsDelegateWhenTapped() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")
        let view = ReplyComposingView(message: message)
        let delegate = ReplyComposingViewMockDelegate()
        view.delegate = delegate
        XCTAssertEqual(delegate.composingViewWantsToShowMessage, 0)
        // WHEN
        view.onTap()
        // THEN
        XCTAssertEqual(delegate.composingViewWantsToShowMessage, 1)
    }
    
    func testThatItCallsDelegateWhenXCalled() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")
        let view = ReplyComposingView(message: message)
        let delegate = ReplyComposingViewMockDelegate()
        view.delegate = delegate
        XCTAssertEqual(delegate.didCancelCalledCount, 0)
        // WHEN
        view.closeButton.sendActions(for: .touchUpInside)
        // THEN
        XCTAssertEqual(delegate.didCancelCalledCount, 1)
    }
    
}
