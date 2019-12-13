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

class GroupConversationCellTests: CoreDataSnapshotTestCase {
        
    func cell(_ configuration : (GroupConversationCell) -> Void) -> GroupConversationCell {
        let cell = GroupConversationCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        configuration(cell)
        cell.layoutIfNeeded()
        return cell
    }
    
    func testOneToOneConversation() {
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(conversation: otherUserConversation)
        }))
    }
    
    func testGroupConversation() {
        let groupConversation = createGroupConversation()
        for username in usernames.prefix(upTo: 3) {
            groupConversation.add(participants:createUser(name: username))
        }
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(conversation: groupConversation)
        }))
    }
    
    func testGroupConversationWithVeryLongName() {
        let groupConversation = createGroupConversation()
        groupConversation.userDefinedName  = "Loooooooooooooooooooooooooong name"
        for username in usernames.prefix(upTo: 3) {
            groupConversation.add(participants:[createUser(name: username)])
        }
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(conversation: groupConversation)
        }))
    }
    
}

