//
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
import SnapshotTesting
@testable import Wire

private final class MockConversation: MockGroupDetailsConversation & SortedActiveParticipantProvider & VerifyLegalHoldSubjectsProvider {
    var sortedActiveParticipantsUserTypes: [UserType] = []
    
    func verifyLegalHoldSubjects() {
        //no-op
    }
}



final class LegalHoldDetailsViewControllerSnapshotTests: XCTestCase {

    var sut: LegalHoldDetailsViewController!
    var wrappedInVC: UINavigationController!
    var selfUser: MockUserType!
    var otherUser: MockUserType!

    override func setUp() {
        super.setUp()
        
        SelfUser.setupMockSelfUser(inTeam: UUID())
        selfUser = (SelfUser.current as! MockUserType)
        otherUser = MockUserType.createDefaultOtherUser()
    }

    override func tearDown() {
        sut = nil
        wrappedInVC = nil
        otherUser = nil
        SelfUser.provider = nil

        super.tearDown()
    }

    /*private func verifyInColorThemes(conversation: MockConversation,
                                     file: StaticString = #file,
                                     testName: String = #function,
                                     line: UInt = #line) {
        ColorScheme.default.variant = .dark
        sut = LegalHoldDetailsViewController(conversation: conversation.convertToRegularConversation())
        wrappedInVC = sut.wrapInNavigationController()
        verify(matching: wrappedInVC, named: "DarkTheme", file: file, testName: testName, line: line)

        ColorScheme.default.variant = .light
        sut = LegalHoldDetailsViewController(conversation: conversation.convertToRegularConversation())
        wrappedInVC = sut.wrapInNavigationController()
        verify(matching: wrappedInVC, named: "LightTheme", file: file, testName: testName, line: line)
    }*/

    func testSelfUserUnderLegalHold() {
        
        let conversation = MockConversation()
        selfUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [selfUser]
        
        verifyInAllColorSchemes(createSut: {
            self.sut = LegalHoldDetailsViewController(conversation: conversation)
            wrappedInVC = self.sut.wrapInNavigationController()
            return wrappedInVC
        })

//        verifyInColorThemes(conversation: conversation)
    }
    
    /*func testOtherUserUnderLegalHold() {
        let conversation = MockConversation.groupConversation(selfUser: MockUser.mockSelf(), otherUser: MockUser.mockUsers().first!)
        conversation.sortedActiveParticipants.forEach({ user in
            let mockUser = user as? MockUser

            if mockUser?.isSelfUser == false {
                mockUser?.isUnderLegalHold = true
            }
        })

        verifyInColorThemes(conversation: conversation) ///TODO: crash
    }*/

}
