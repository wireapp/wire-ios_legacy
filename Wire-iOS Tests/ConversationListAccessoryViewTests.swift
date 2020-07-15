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

final class ConversationListAccessoryViewTests: XCTestCase {
    var sut: ConversationListAccessoryView!
    
    override func setUp() {
        super.setUp()
        self.sut = ConversationListAccessoryView(mediaPlaybackManager: MediaPlaybackManager(name: "test"))
        accentColor = .violet
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItIsEmptyForNoStatus() {
        // WHEN
        sut.icon = nil
        // THEN
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        XCTAssertEqual(sut.frame.size.width, 0)
    }
    
    func testThatItShowsUnreadMessages() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadMessages(count: 3)
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsALotOfUnreadMessages() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadMessages(count: 500)
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsJoinButton() {
        // WHEN
        sut.icon = ConversationStatusIcon.activeCall(showJoin: true)
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsOngoingCallIndicator() {
        // WHEN
        sut.icon = ConversationStatusIcon.activeCall(showJoin: false)
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsMissedCall() {
        // WHEN
        sut.icon = ConversationStatusIcon.missedCall
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsMissedPing() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadPing
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsTyping() {
        // WHEN
        sut.icon = ConversationStatusIcon.typing
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsSilenced() {
        // WHEN
        sut.icon = ConversationStatusIcon.silenced
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsPlayingMedia() {
        // WHEN
        sut.icon = ConversationStatusIcon.playingMedia
        // THEN
        verify(matching: sut)
    }
    
    func testThatItShowsPendingConnection() {
        // WHEN
        sut.icon = ConversationStatusIcon.pendingConnection
        // THEN
        verify(matching: sut)
    }
    
    func testThatItRecoversFromPreviousState() {
        // WHEN
        sut.icon = ConversationStatusIcon.unreadPing
        sut.icon = ConversationStatusIcon.typing

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsMention() {
        // WHEN
        sut.icon = ConversationStatusIcon.mention
        // THEN
        verify(matching: sut)
    }

    func testThatItShowsReply() {
        // WHEN
        sut.icon = ConversationStatusIcon.reply
        // THEN
        verify(matching: sut)
    }
}
