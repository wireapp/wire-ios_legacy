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
@testable import Wire

final class ConversationAvatarViewTests: XCTestCase {

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
        let conversation = MockStableRandomParticipantsConversation()

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersSomeAndThenNoUserImages() {
        // GIVEN
        let otherUserConversation = MockStableRandomParticipantsConversation()

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // AND WHEN
        _ = sut.prepareForSnapshots()

        // AND WHEN

        let conversation = MockStableRandomParticipantsConversation()

        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersSingleUserImage() {
        // GIVEN
        let otherUserConversation = MockStableRandomParticipantsConversation()
        let otherUser = MockUserType.createDefaultOtherUser()
        otherUser.accentColorValue = .strongLimeGreen
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersPendingConnection() {
        // GIVEN
        let otherUser = MockUserType.createDefaultOtherUser()
        otherUser.accentColorValue = .strongLimeGreen
        otherUser.isConnected = false
        otherUser.isPendingApprovalBySelfUser = true
        let otherUserConversation = MockStableRandomParticipantsConversation()
        otherUserConversation.conversationType = .connection
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .connect(users: [otherUser]))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersASingleServiceUser() {
        // GIVEN
        let otherUser = MockServiceUserType()
        otherUser.initials = "B"
        otherUser.serviceIdentifier = "serviceIdentifier"
        otherUser.providerIdentifier = "providerIdentifier"
        otherUser.isConnected = true
        XCTAssert(otherUser.isServiceUser)

        otherUser.accentColorValue = .strongLimeGreen
        let otherUserConversation = MockStableRandomParticipantsConversation()
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersTwoUserImages() {
        // GIVEN
        let conversation = MockStableRandomParticipantsConversation()
        let otherUser = MockUserType.createDefaultOtherUser()
        let thirdUser = MockUserType.createConnectedUser(name: "Anna")
        thirdUser.accentColorValue = .vividRed
        conversation.stableRandomParticipants = [thirdUser, otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersManyUsers() {
        // GIVEN

        let conversation = MockStableRandomParticipantsConversation()
        conversation.stableRandomParticipants = MockUserType.usernames.map {MockUserType.createConnectedUser(name: $0)}

        (conversation.stableRandomParticipants[0] as! MockUserType).accentColorValue = .vividRed
        (conversation.stableRandomParticipants[1] as! MockUserType).accentColorValue = .brightOrange
        (conversation.stableRandomParticipants[2] as! MockUserType).accentColorValue = .brightYellow
        (conversation.stableRandomParticipants[3] as! MockUserType).accentColorValue = .strongBlue

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        verify(matching: sut.prepareForSnapshots())
    }

}

fileprivate extension UIView {

    func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 24),
            container.widthAnchor.constraint(equalToConstant: 24),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        return container
    }

}
