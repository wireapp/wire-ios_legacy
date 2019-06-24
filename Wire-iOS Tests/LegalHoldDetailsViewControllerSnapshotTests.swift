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

import Foundation
@testable import Wire

class LegalHoldDetailsViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    
    override func setUp() {
        super.setUp()
    }
    
    var sut: LegalHoldDetailsViewController!
    
    func testSelfUserUnderLegalHold() {
        
        let conversation = MockConversation.groupConversation()
        let selfUser = MockUser.mockSelf()
        selfUser?.isUnderLegalHold = true
        
        ColorScheme.default.variant = .dark
        sut = LegalHoldDetailsViewController(conversation: conversation.convertToRegularConversation())
        verify(view: sut.view, identifier: "DarkTheme")
        
        ColorScheme.default.variant = .light
        sut = LegalHoldDetailsViewController(conversation: conversation.convertToRegularConversation())
        verify(view: sut.view, identifier: "LightTheme")
    }
    
    func testOtherUserUnderLegalHold() {
        
        let conversation = MockConversation.groupConversation()
        conversation.sortedActiveParticipants.forEach({ user in
            let mockUser = user as? MockUser
            
            if mockUser?.isSelfUser == false {
                mockUser?.isUnderLegalHold = true
            }
        })
        
        ColorScheme.default.variant = .dark
        sut = LegalHoldDetailsViewController(conversation: conversation.convertToRegularConversation())
        verify(view: sut.view, identifier: "DarkTheme")
     
        ColorScheme.default.variant = .light
        sut = LegalHoldDetailsViewController(conversation: conversation.convertToRegularConversation())
        verify(view: sut.view, identifier: "LightTheme")
    }
    
}
