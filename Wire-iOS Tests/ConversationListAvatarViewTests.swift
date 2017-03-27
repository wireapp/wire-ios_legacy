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


class ConversationListAvatarViewTests: CoreDataSnapshotTestCase {

    var sut: ConversationListAvatarView!

    override func setUp() {
        super.setUp()
        sut = ConversationListAvatarView()
    }

    func testThatItRendersSingleUserImage() {
        otherUser.accentColorValue = .strongLimeGreen
        otherUserConversation.conversationType = .oneOnOne
        sut.conversation = otherUserConversation
        moc.saveOrRollback()

        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersTwoUserImages() {
        let thirdUser = ZMUser.insertNewObject(in: moc)
        thirdUser.name = "Anna"
        let conversation = ZMConversation.insertGroupConversation(into: moc, withParticipants: [otherUser, thirdUser])
        sut.conversation = conversation
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersManyUsers() {
        let conversation = ZMConversation.insertGroupConversation(into: moc, withParticipants: usernames.map(createUser))
        sut.conversation = conversation
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
