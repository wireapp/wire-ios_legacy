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

import UIKit
@testable import Wire

class FolderPickerControllerSnapshotTests: CoreDataSnapshotTestCase {

    var sut: FolderPickerViewController!
    
    override func setUp() {
        super.setUp()
        
        let convo = createTeamGroupConversation()
        sut = FolderPickerViewController(conversation: convo,
                                         folders: ["Folder A", "Folder B", "Folder C"])
        accentColor = .violet
    }
    
    override func tearDown() {
        sut = nil
        ColorScheme.default.variant = .light
        super.tearDown()
    }
    
    func testForDisplayingView() {
        
        sut.loadViewIfNeeded()
        
        sut.viewDidAppear(false)
        
        verify(view: sut.view)
    }
}
