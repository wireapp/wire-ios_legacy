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

private let accentColors: [ZMAccentColor] = [.vividRed, .softPink, .brightYellow, .strongBlue, .strongLimeGreen]

extension Array where Element: ZMUser {

    func assignSomeAccentColors() {
        var index = 0
        for user in self {
            user.accentColorValue = accentColors[index % accentColors.count]
            user.connection = ZMConnection.insertNewSentConnection(to: user)
            user.connection!.status = .accepted
            
            index = index + 1
        }
    }
}

class ConversationAvatarViewTests: CoreDataSnapshotTestCase {

    var sut: ConversationAvatarView!

    override func setUp() {
        super.setUp()
        sut = ConversationAvatarView()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersNoUserImages() {
        // GIVEN
        let thirdUser = ZMUser.insertNewObject(in: uiMOC)
        thirdUser.name = "Anna"
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [otherUser, thirdUser])
        conversation?.internalRemoveParticipants(Set([selfUser!, otherUser!, thirdUser]), sender: selfUser)

        // WHEN
        sut.conversation = conversation
        
        // THEN
        verify(view: sut.prepareForSnapshots())
    }

    
    func testThatItRendersSomeAndThenNoUserImages() {
        // GIVEN
        otherUser.accentColorValue = .strongLimeGreen
        otherUserConversation.conversationType = .oneOnOne
        uiMOC.saveOrRollback()
        
        // WHEN
        sut.conversation = otherUserConversation
        
        // AND WHEN
        _ = sut.prepareForSnapshots()
        
        // AND WHEN
        let thirdUser = ZMUser.insertNewObject(in: uiMOC)
        thirdUser.name = "Anna"
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [otherUser, thirdUser])
        conversation?.internalRemoveParticipants(Set([selfUser!, otherUser!, thirdUser]), sender: selfUser)
        
        sut.conversation = conversation
        
        // THEN
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersSingleUserImage() {
        // GIVEN
        otherUser.accentColorValue = .strongLimeGreen
        otherUserConversation.conversationType = .oneOnOne
        uiMOC.saveOrRollback()
        
        // WHEN
        sut.conversation = otherUserConversation

        // THEN
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersPendingConnection() {
        // GIVEN
        otherUser.accentColorValue = .strongLimeGreen
        otherUserConversation.conversationType = .connection
        otherUserConversation.connection?.status = .pending
        uiMOC.saveOrRollback()
        
        // WHEN
        sut.conversation = otherUserConversation
        
        // THEN
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersASingleServiceUser() {
        // GIVEN
        otherUser.serviceIdentifier = "serviceIdentifier"
        otherUser.providerIdentifier = "providerIdentifier"
        XCTAssert(otherUser.isServiceUser)

        otherUser.accentColorValue = .strongLimeGreen
        otherUserConversation.conversationType = .oneOnOne
        uiMOC.saveOrRollback()
        
        // WHEN
        sut.conversation = otherUserConversation
        
        // THEN
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersTwoUserImages() {
        // GIVEN
        let thirdUser = ZMUser.insertNewObject(in: uiMOC)
        thirdUser.name = "Anna"
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: [otherUser, thirdUser])
        
        (conversation?.activeParticipants.array as! [ZMUser]).assignSomeAccentColors()
        
        // WHEN
        sut.conversation = conversation
        
        // THEN
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersManyUsers() {
        // GIVEN
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: usernames.map(createUser))
        
        (conversation?.activeParticipants.array as! [ZMUser]).assignSomeAccentColors()
        
        // WHEN
        sut.conversation = conversation
        
        // THEN
        verify(view: sut.prepareForSnapshots())
    }

}

fileprivate extension UIView {

    func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.addSubview(self)

        constrain(container, self) { container, view in
            container.height == 24
            container.width == 24
            view.edges == container.edges
        }

        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }

}
