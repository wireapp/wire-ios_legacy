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

class MentionsSearchResultsViewControllerTests: CoreDataSnapshotTestCase {

    var sut: MentionsSearchResultsViewController!
    
    override func setUp() {
        super.setUp()
        
        sut = MentionsSearchResultsViewController(nibName: nil, bundle: nil)
        
        sut.view.layoutIfNeeded()
        sut.view.layer.speed = 0

        sut.viewDidLoad()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWithTwoUsers() {
        sut.reloadTable(with: [selfUser, otherUser])
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    func testThatDoesntOverflowWithTooManyUsers() {
        var users: [ZMUser] = []
        for name in usernames {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = UUID()
            user.name = name
            user.setHandle(name.lowercased())
            user.accentColorValue = .brightOrange
            uiMOC.saveOrRollback()
            users.append(user)
        }
        
        sut.reloadTable(with: users)
        
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    
}
