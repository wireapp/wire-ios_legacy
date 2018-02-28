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
        
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        MockUser.mockSelf().isTeamMember = false
        super.tearDown()
    }
    
    func cell(_ configuration : (GroupDetailsParticipantCell) -> Void) -> GroupDetailsParticipantCell {
        let cell = GroupDetailsParticipantCell(frame: CGRect(x: 0, y: 0, width: 320, height: 64))
        configuration(cell)
        cell.layoutIfNeeded()
        return cell
    }
    
    func testNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        
        verify(view: cell({ (cell) in
            cell.configure(with: user)
        }))
    }
    
    func testTrustedNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.configure(with: user)
        }))
    }
    
    func testTrustedNonTeamUser_DarkMode() {
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.variant = .dark
            cell.configure(with: user)
        }))
    }
    
    func testNonTeamUser_DarkMode() {
        let user = MockUser.mockUsers()[0]
        
        verify(view: cell({ (cell) in
            cell.variant = .dark
            cell.configure(with: user)
        }))
    }
    
    func testGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        
        verify(view: cell({ (cell) in
            cell.configure(with: user)
        }))
    }
    
    func testGuestUser_DarkMode() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        
        verify(view: cell({ (cell) in
            cell.variant = .dark
            cell.configure(with: user)
        }))
    }
    
    func testTrustedGuestUser() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.configure(with: user)
        }))
    }
    
    func testTrustedGuestUser_DarkMode() {
        MockUser.mockSelf().isTeamMember = true
        let user = MockUser.mockUsers()[0]
        let mockUser = MockUser(for: user)
        mockUser?.trusted = true
        _ = mockUser?.feature(withUserClients: 1)
        
        verify(view: cell({ (cell) in
            cell.variant = .dark
            cell.configure(with: user)
        }))
    }
    
    func testNonTeamUserWithoutHandle() {
        let user = MockUser.mockUsers()[10]
        
        verify(view: cell({ (cell) in
            cell.configure(with: user)
        }))
    }
    
    func testNonTeamUserWithoutHandle_DarkMode() {
        let user = MockUser.mockUsers()[10]
        
        verify(view: cell({ (cell) in
            cell.variant = .dark
            cell.configure(with: user)
        }))
    }
    
}
