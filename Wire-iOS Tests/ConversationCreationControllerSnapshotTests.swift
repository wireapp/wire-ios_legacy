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

final class ConversationCreationControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: ConversationCreationController!
    
    override func setUp() {
        super.setUp()
        sut = ConversationCreationController()
        accentColor = .violet
    }
    
    override func tearDown() {
        sut = nil
        ColorScheme.default.variant = .light
        super.tearDown()
    }

    func testForEditingTextField() {

        sut.loadViewIfNeeded()
        sut.beginAppearanceTransition(false, animated: false)
        sut.endAppearanceTransition()

        sut.viewDidAppear(false)

        verify(view: sut.view)
    }
    
    func testTeamGroupOptionsCollapsed() {
        teamTest {
            self.sut.loadViewIfNeeded()
            self.sut.viewDidAppear(false)

            verify(view: self.sut.view)
        }
    }

    func testTeamGroupOptionsCollapsed_dark() {
        ColorScheme.default.variant = .dark

        teamTest {
            self.sut.loadViewIfNeeded()
            self.sut.viewDidAppear(false)

            sut.view.backgroundColor = .black
            verify(view: self.sut.view)
        }
    }

    func testTeamGroupOptionsExpanded() {
        teamTest {
            self.sut.loadViewIfNeeded()
            self.sut.optionsExpanded = true
            
            verify(view: self.sut.view)
        }
    }
}
