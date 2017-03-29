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

import Foundation
import XCTest
@testable import Wire

class ConversationListAccessoryViewTests: ZMSnapshotTestCase {
    let sut = ConversationListAccessoryView(mediaPlaybackManager: MediaPlaybackManager(name: "test"))
    
    override func setUp() {
        super.setUp()
        accentColor = .violet
    }

    func testThatItIsEmptyForNoStatus() {
        // WHEN
        sut.icon = ConversationStatusIcon.none
        // THEN
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        XCTAssertEqual(sut.frame.size.width, 0)
    }
    
    func testThatItShowsUnreadMessages() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadMessages(count: 3)
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsALotOfUnreadMessages() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadMessages(count: 500)
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsJoinButton() {
        // WHEN
        sut.icon = ConversationStatusIcon.activeCall(joined: false)
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsMissedCall() {
        // WHEN
        sut.icon = ConversationStatusIcon.missedCall
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsMissedPing() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadPing
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsTyping() {
        // WHEN
        sut.icon = ConversationStatusIcon.typing
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsSilenced() {
        // WHEN
        sut.icon = ConversationStatusIcon.silenced
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsPlayingMedia() {
        // WHEN
        sut.icon = ConversationStatusIcon.playingMedia
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsPendingConnection() {
        // WHEN
        sut.icon = ConversationStatusIcon.pendingConnection
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRecoversFromPreviousState() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadPing
        sut.icon = ConversationStatusIcon.typing

        // THEN
        self.verify(view: sut.snapshotView())
    }
}


fileprivate extension UIView {
    func snapshotView() -> UIView {
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}

