
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class MockConversationAvatarViewConversation: SwiftMockConversation, StableRandomParticipantsProvider {
    var stableRandomParticipants: [UserType] = []
}

final class ConversationAvatarViewModeTests: XCTestCase {
    var sut: ConversationAvatarView!
    var otherUser: MockUserType!
    var mockConversation: MockConversationAvatarViewConversation!
    
    override func setUp() {
        super.setUp()
        
        mockConversation = MockConversationAvatarViewConversation()
            
        otherUser = MockUserType.createDefaultOtherUser()
        sut = ConversationAvatarView()
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil
        otherUser = nil
        
        super.tearDown()
    }

    func testThatModeIsOneWhenGroupConversationWithOneServiceUser() {
        // GIVEN
        let mockServiceUser = MockServiceUserType()
        mockServiceUser.serviceIdentifier = "serviceIdentifier"
        mockServiceUser.providerIdentifier = "providerIdentifier"
        XCTAssert(mockServiceUser.isServiceUser)

        mockConversation.stableRandomParticipants = [mockServiceUser]

        // WHEN
        sut.configure(context: .conversation(conversation: mockConversation))

        // THEN
        XCTAssertEqual(sut.mode, .one(serviceUser: true))
    }

    func testThatModeIsFourWhenGroupConversationWithOneUser() {
        // GIVEN
        mockConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: mockConversation))

        // THEN
        XCTAssertEqual(sut.mode, .four)
    }

    func testThatModeIsNoneWhenGroupConversationIsEmpty() {
        // GIVEN

        // WHEN
        sut.configure(context: .conversation(conversation: mockConversation))

        // THEN
        XCTAssertEqual(sut.mode, .none)
    }
}
