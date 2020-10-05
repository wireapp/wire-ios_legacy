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

import SnapshotTesting
import XCTest
@testable import Wire

final class ConversationCreationControllerSnapshotTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    var sut: ConversationCreationController!
    
    override func setUp() {
        super.setUp()
        sut = ConversationCreationController()
        accentColor = .violet
        coreDataFixture = CoreDataFixture()
    }
    
    override func tearDown() {
        sut = nil
        ColorScheme.default.variant = .light
        coreDataFixture = nil
        super.tearDown()
    }

    func testForEditingTextField() {

        sut.loadViewIfNeeded()
        sut.beginAppearanceTransition(false, animated: false)
        sut.endAppearanceTransition()

        sut.viewDidAppear(false)

        verify(matching: sut)
    }
    
    func testTeamGroupOptionsCollapsed() {
        teamTest {
            self.sut.loadViewIfNeeded()
            self.sut.viewDidAppear(false)

            verify(matching: sut)
        }
    }

    func testTeamGroupOptionsCollapsed_dark() {
        ColorScheme.default.variant = .dark

        teamTest {
            self.sut.loadViewIfNeeded()
            self.sut.viewDidAppear(false)

            sut.view.backgroundColor = .black
            verify(matching: sut)
        }
    }

    func testTeamGroupOptionsExpanded() {        
        teamTest {
            self.sut.loadViewIfNeeded()
            self.sut.optionsExpanded = true
            
            verify(matching: sut)
        }
    }
}
