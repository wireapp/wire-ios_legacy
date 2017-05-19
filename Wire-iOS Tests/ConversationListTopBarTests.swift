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

import Foundation
import XCTest
import Cartography
@testable import Wire

class MockTeam: TeamType {
    public var conversations: Set<ZMConversation> = Set()
    public var name: String? = ""
    public var teamPictureAssetKey: String? = .none
    public var isActive: Bool = true
    public var remoteIdentifier: UUID? = .none
}

class ConversationListTopBarTests: ZMSnapshotTestCase {
    let sut = ConversationListTopBar()
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        scrollView.contentSize = CGSize(width: 320, height: 800)
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        return scrollView
    }()
    
    func createTeams(createFamily: Bool = false) -> [TeamType] {
        let workspaceName = "W"
        
        var teams: [TeamType] = []
        
        let workTeam: TeamType = {
            let workTeam = MockTeam()
            workTeam.name = workspaceName
            workTeam.isActive = false
            return workTeam
        }()
        
        teams.append(workTeam)
        
        if createFamily {
            let familyTeam: TeamType = {
                let familyTeam = MockTeam()
                familyTeam.name = "Family"
                familyTeam.isActive = false
                return familyTeam
            }()
            
            teams.append(familyTeam)
        }
        
        return teams
    }
    
    override func setUp() {
        super.setUp()
        sut.contentScrollView = scrollView
        self.snapshotBackgroundColor = UIColor(white: 0, alpha: 0.8)
    }
    
    func testThatItRendersDefaultBar() {
        // GIVEN & WHEN
        sut.teams = []
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBar() {
        // GIVEN & WHEN
        sut.teams = createTeams()
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarScrolledAway() {
        // GIVEN & WHEN
        sut.teams = createTeams()
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarThreeSpaces() {
        // GIVEN & WHEN
        sut.teams = createTeams(createFamily: true)
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarThreeSpacesScrolledAway() {
        // GIVEN & WHEN
        sut.teams = createTeams(createFamily: true)
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarSecondOneSelected() {
        // GIVEN & WHEN
        sut.teams = createTeams()
        sut.teams.first!.isActive = true
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarOneSelectedScrolledAway() {
        // GIVEN & WHEN
        sut.teams = createTeams()
        sut.teams.first!.isActive = true
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarAfterDefaultBar() {
        // GIVEN & WHEN
        
        sut.teams = []
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        sut.teams = createTeams()
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarAfterDefaultBar_ScrolledAway() {
        // GIVEN & WHEN
        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        sut.teams = []
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        sut.teams = createTeams()
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersDefaultBarAfterSpacesBar() {
        // GIVEN & WHEN
        sut.teams = createTeams()
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        sut.teams = []
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
}

fileprivate extension UIView {
    func snapshotView() -> UIView {
        constrain(self) { cell in
            cell.width == 320
        }
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}

