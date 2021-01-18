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

final class UserCellTests: ZMSnapshotTestCase {
    
    var mockConversation: MockConversation!
    
    var conversation : ZMConversation {
        return (mockConversation as Any) as! ZMConversation
    }
        
    override func setUp() {
        super.setUp()
                
        mockConversation = MockConversationFactory.mockConversation()
    }
    
    override func tearDown() {
        MockUser.mockSelf().isTeamMember = false
        mockConversation = nil
        super.tearDown()
    }
    
    func cell(_ configuration : (UserCell) -> Void) -> UserCell {
        let cell = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        cell.accessoryIconView.isHidden = false
        configuration(cell)
        cell.layoutIfNeeded()
        return cell
    }

    func testExternalUser() {
        MockUser.mockSelf().isTeamMember = true
        let mockUser = MockUser.firstMockUser()
        mockUser.isTeamMember = true
        mockUser.teamRole = .partner
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: mockUser,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }

    func testServiceUser() {
        MockUser.mockSelf().isTeamMember = true
        let mockUser = MockUser.firstMockUser()
        mockUser.isServiceUser = true
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: mockUser,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }
    
    func testNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }
    
    func testTrustedNonTeamUser() {
        let mockUser = MockUser.firstMockUser()

        mockUser.isVerified = true
        _ = mockUser.feature(withUserClients: 1)
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: mockUser,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }
    
    func testGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let mockUser = MockUser.firstMockUser()

        mockUser.isGuestInConversation = true
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: mockUser,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }
    
    func testGuestUser_Wireless() {
        MockUser.mockSelf().isTeamMember = true
        let mockUser = MockUser.firstMockUser()
        mockUser.isGuestInConversation = true
        mockUser.expiresAfter = 5_200
        mockUser.handle = nil

        verifyInAllColorSchemes(view: cell {
            $0.configure(with: mockUser,
                         selfUser: MockUser.mockSelf(),
                         conversation: conversation)
        })
    }
    
    func testTrustedGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        
        let mockUser = MockUser.firstMockUser()
        mockUser.isVerified = true

        mockUser.isGuestInConversation = true
        _ = mockUser.feature(withUserClients: 1)

        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: mockUser,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }
    
    func testNonTeamUserWithoutHandle() {
        let user = MockUser.mockUsers()[10]
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user,
                           selfUser: MockUser.mockSelf(),
                           conversation: conversation)
        }))
    }
    
    
    func testUserInsideOngoingVideoCall() {
        let user = MockUser.mockUsers()[0]
        verifyInAllColorSchemes(view: cell({ (cell) in
            let config = CallParticipantsCellConfiguration.callParticipant(user: HashBox(value: user), videoState: .started, microphoneState: .unmuted, isActiveSpeaker: false)
            cell.configure(with: config, variant: .dark, selfUser: MockUser.mockSelf())
        }))
    }
    
    func testUserScreenSharingInsideOngoingVideoCall() {
        let user = MockUser.mockUsers()[0]
        verifyInAllColorSchemes(view: cell({ (cell) in
            let config = CallParticipantsCellConfiguration.callParticipant(user: HashBox(value: user), videoState: .screenSharing, microphoneState: .unmuted, isActiveSpeaker: false)
            cell.configure(with: config, variant: .dark, selfUser: MockUser.mockSelf())
        }))
    }
    
    func testThatAccessIDIsGenerated() {
        let user = MockUser.mockUsers().map(ParticipantsRowType.init)[0]
        
        let cell = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        cell.sectionName = "Members"
        cell.cellIdentifier = "participants.section.participants.cell"
        cell.configure(with: user, conversation: conversation, showSeparator: true)
        XCTAssertEqual(cell.accessibilityIdentifier, "Members - participants.section.participants.cell")
    }
    
}
