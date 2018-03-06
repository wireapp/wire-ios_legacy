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

class GroupDetailsParticipantCellTests: ZMSnapshotTestCase {
    
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
    
    func cell(_ configuration : (GroupDetailsParticipantCell) -> Void) -> GroupDetailsParticipantCell {
        let cell = GroupDetailsParticipantCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        configuration(cell)
        cell.layoutIfNeeded()
        return cell
    }
    
    func testServiceUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.isServiceUser = true
        
        verify(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        
        verify(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testTrustedNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testTrustedNonTeamUser_DarkMode() {
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.colorSchemeVariant = .dark
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testNonTeamUser_DarkMode() {
        let user = MockUser.mockUsers()[0]
        
        verify(view: cell({ (cell) in
            cell.colorSchemeVariant = .dark
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.isGuestInConversation = true
        
        verify(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testGuestUser_DarkMode() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.isGuestInConversation = true
        
        verify(view: cell({ (cell) in
            cell.colorSchemeVariant = .dark
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testTrustedGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        mockUser?.isGuestInConversation = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testTrustedGuestUser_DarkMode() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        mockUser?.isGuestInConversation = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.colorSchemeVariant = .dark
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testNonTeamUserWithoutHandle() {
        let user = MockUser.mockUsers()[10]
        
        verify(view: cell({ (cell) in
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
    func testNonTeamUserWithoutHandle_DarkMode() {
        let user = MockUser.mockUsers()[10]
        
        verify(view: cell({ (cell) in
            cell.colorSchemeVariant = .dark
            cell.configure(with: user, conversation: conversation)
        }))
    }
    
}
