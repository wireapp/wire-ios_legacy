//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class ProfileDetailsViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: ProfileDetailsViewController!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState() {
        sut = ProfileDetailsViewController(user: self.otherUser, conversation: self.otherUserConversation, context: .oneToOneConversation)
        verify(view: sut.view)
    }
    
    func testSmallScreen_expiringUser() {
        sut = ProfileDetailsViewController(user: self.otherUser, conversation: self.otherUserConversation, context: .oneToOneConversation)
        self.otherUser.setValue(Date(timeIntervalSinceNow: 3600), forKey: "expiresAt")
        verifyInIPhoneSize(view: sut.view)
    }
    
    func testSmallScreen_expiringGuest() {
        // given
        let selfUser = self.selfUser
        selfUser?.teamIdentifier = UUID()
        
        let groupConversation = self.createGroupConversation()
        groupConversation.teamRemoteIdentifier = UUID()
        
        sut = ProfileDetailsViewController(user: self.otherUser, conversation: groupConversation, context: .oneToOneConversation)
        
        self.otherUser.setValue(Date(timeIntervalSinceNow: 3600), forKey: "expiresAt")
        // when & then
        verifyInIPhoneSize(view: sut.view)
    }
    
    func testExpiringGuestReadReceipts() {
        // given
        let selfUser = self.selfUser
        selfUser?.teamIdentifier = UUID()
        selfUser?.readReceiptsEnabled = true
        
        let groupConversation = self.createGroupConversation()
        groupConversation.teamRemoteIdentifier = UUID()
        
        sut = ProfileDetailsViewController(user: self.otherUser, conversation: groupConversation, context: .oneToOneConversation)
        
        self.otherUser.setValue(Date(timeIntervalSinceNow: 3600), forKey: "expiresAt")
        // when & then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testForActionMenu() {
        sut = ProfileDetailsViewController(user: self.otherUser, conversation: self.otherUserConversation, context: .oneToOneConversation)
        teamTest {
            sut.presentMenuSheetController()
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_NoTeam() {
        sut = ProfileDetailsViewController(user: self.otherUser, conversation: self.otherUserConversation, context: .oneToOneConversation)
        nonTeamTest {
            sut.presentMenuSheetController()
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }
}
