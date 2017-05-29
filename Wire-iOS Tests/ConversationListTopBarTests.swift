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

class ConversationListTopBarTests: CoreDataSnapshotTestCase {
    var sut: ConversationListTopBar!
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        scrollView.contentSize = CGSize(width: 320, height: 800)
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        return scrollView
    }()
    
    func removeTeams() {
        self.selfUser.mutableSetValue(forKey: "memberships").removeAllObjects()
        moc.saveOrRollback()
    }
    
    @discardableResult func createTeams(createFamily: Bool = false) -> [TeamType] {
        let workspaceName = "W"
        
        var teams: [Team] = []
        
        let workTeam: Team = {
            let workTeam = Team.insertNewObject(in: moc)
            workTeam.name = workspaceName
            workTeam.isActive = false
            return workTeam
        }()
        
        teams.append(workTeam)
        
        if createFamily {
            let familyTeam: Team = {
                let familyTeam = Team.insertNewObject(in: moc)
                familyTeam.name = "Family"
                familyTeam.isActive = false
                return familyTeam
            }()
            
            teams.append(familyTeam)
        }
        
        self.selfUser.mutableSetValue(forKey: "memberships").addObjects(from: teams.map {
            
            let membership = Member.insertNewObject(in: moc)
            membership.team = $0
            membership.user = self.selfUser
            return membership
        })
        moc.saveOrRollback()
        return teams
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        MockUser.setMockSelf(nil)
    }
    
    override func setUp() {
        super.setUp()
        MockUser.setMockSelf(self.selfUser)
        self.snapshotBackgroundColor = UIColor(white: 0, alpha: 0.8)
    }
    
    func testThatItRendersDefaultBar() {
        // GIVEN & WHEN
        removeTeams()
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBar() {
        // GIVEN & WHEN
        createTeams()
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarScrolledAway() {
        // GIVEN & WHEN
        createTeams()
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarThreeSpaces() {
        // GIVEN & WHEN
        createTeams(createFamily: true)
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func disabled_testThatItRendersSpacesBarThreeSpacesScrolledAway() {
        // GIVEN & WHEN
        createTeams(createFamily: true)
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarSecondOneSelected() {
        // GIVEN & WHEN
        let teams = createTeams()
        teams.first!.isActive = true
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarOneSelectedScrolledAway() {
        // GIVEN & WHEN
        let teams = createTeams()
        teams.first!.isActive = true
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarAfterDefaultBar() {
        // GIVEN & WHEN
        
        self.sut = ConversationListTopBar()
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        createTeams()
        sut.update(to: ConversationListTopBar.ImagesState.visible, force: true)
        self.sut.updateShowTeamsIfNeeded()

        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarAfterDefaultBar_ScrolledAway() {
        // GIVEN & WHEN
        self.sut = ConversationListTopBar()
        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        createTeams()
        self.sut.updateShowTeamsIfNeeded()
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersDefaultBarAfterSpacesBar() {
        // GIVEN & WHEN
        createTeams()
        self.sut = ConversationListTopBar()

        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        removeTeams()
        self.sut.updateShowTeamsIfNeeded()

        // THEN
        self.verify(view: sut.snapshotView())
    }
}

fileprivate extension UIView {
    func snapshotView() -> UIView {
        constrain(self) { selfView in
            selfView.width == 320
            selfView.height == 70
        }
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}

