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

import XCTest
import Cartography
@testable import Wire

class ChatHeadTests: CoreDataSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
    }
    
    func chatHead(title: String?, body: String, teamName: String = "Wire", ephemeral: Bool = false) -> ChatHeadView {
        return ChatHeadView(
            title: title == nil ? nil : "\(title!) in \(teamName)".trimmingCharacters(in: .whitespaces),
            body: body,
            sender: otherUser,
            userID: selfUser.remoteIdentifier!,
            teamName: teamName,
            isEphemeral: ephemeral
        )
    }
    
    func testThatItDisplaysAShortMessage() {
        
        let sut = chatHead(title: "iOS Team", body: "Bob: Hey everyone!")
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItDisplaysALongMessage() {
        let sut = chatHead(title: "iOS Team", body: "Bob: Hey everyone! Blah blah blah blah blah blah blah blah")
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersCorrectAttributesForTitle_NoConversationName() {
        let sut = chatHead(title: "", body: "Hey everyone!")
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersCorrectAttributesForTitle_MultipleOccurencesOfIn() {
        let sut = chatHead(title: "Bob in Italy", body: "Hey everyone!", teamName: "Wire in Switzerland")
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItDisplaysSingleLineWhenTitleIsNil() {
        let sut = chatHead(title: nil, body: "Bob is calling")
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersEphemeralContent() {
        let sut = chatHead(title: "iOS Team", body: "Bob: Hey everyone!", ephemeral: true)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItDoesNotDisplayImageWhenThereIsNoSender() {
        let sut = ChatHeadView(
            title: "iOS Team in Wire",
            body: "New message",
            sender: nil,
            userID: selfUser.remoteIdentifier!,
            teamName: "Wire"
        )
        
        verify(view: sut.prepareForSnapshots())
    }
}


fileprivate extension UIView {
    
    func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.addSubview(self)
        
        constrain(container, self) { container, view in
            container.height == 100
            container.width == 375
            view.leading == container.leading + 16
            view.trailing <= container.trailing - 16
            view.centerY == container.centerY
        }
        
        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
}
