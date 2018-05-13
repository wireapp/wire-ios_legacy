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

class UserCellTests: ZMSnapshotTestCase {
    
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
    
    func testServiceUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.isServiceUser = true
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testTrustedNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.isGuestInConversation = true
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testGuestUser_Wireless() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.isGuestInConversation = true
        mockUser?.expiresAfter = 5_200
        mockUser?.handle = nil

        verifyInAllColorSchemes(view: cell {
            $0.configure(with: user, conversation: conversation)
        })
    }
    
    func testTrustedGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        mockUser?.isGuestInConversation = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testNonTeamUserWithoutHandle() {
        let user = MockUser.mockUsers()[10]
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    
    func testUserInsideOngoingVideoCall() {
        let user = MockUser.mockUsers()[0]
        verifyInAllColorSchemes(view: cell({ (cell) in
            let config = CallParticipantsCellConfiguration.callParticipant(user: user, sendsVideo: true)
            cell.configure(with: config, variant: .dark)
        }))
    }
    
}
