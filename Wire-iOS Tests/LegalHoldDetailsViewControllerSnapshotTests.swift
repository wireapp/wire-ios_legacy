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

final class LegalHoldDetailsViewControllerSnapshotTests: XCTestCase {

    var sut: LegalHoldDetailsViewController!
    var wrappedInVC: UINavigationController!
    var selfUser: MockUserType!

    override func setUp() {
        super.setUp()
        
        SelfUser.setupMockSelfUser(inTeam: UUID())
        selfUser = (SelfUser.current as! MockUserType)
    }

    override func tearDown() {
        sut = nil
        wrappedInVC = nil
        SelfUser.provider = nil

        super.tearDown()
    }

    func testSelfUserUnderLegalHold() {
        let conversation = MockGroupDetailsConversation()
        selfUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [selfUser]
        
        let createSut: () -> UIViewController = {
            self.sut = LegalHoldDetailsViewController(conversation: conversation)
            return self.sut.wrapInNavigationController()
        }
        
        verifyInAllColorSchemes(createSut: createSut)
    }
    
    func testOtherUserUnderLegalHold() {
        let conversation = MockGroupDetailsConversation()
        let otherUser = SwiftMockLoader.mockUsers().first!
        otherUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [otherUser]
        
        let createSut: () -> UIViewController = {
            self.sut = LegalHoldDetailsViewController(conversation: conversation)
            return self.sut.wrapInNavigationController()
        }

        verifyInAllColorSchemes(createSut: createSut)
    }

}
