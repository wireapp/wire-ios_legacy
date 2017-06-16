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
    
    func removeTeam() {
        selfUser.setNilValueForKey(#keyPath(ZMUser.membership))
        moc.saveOrRollback()
    }
    
    @discardableResult func createTeam() -> TeamType {
        let team: Team = {
            let workTeam = Team.insertNewObject(in: moc)
            workTeam.name = "W"
            return workTeam
        }()

        let member: Member = {
            let membership = Member.insertNewObject(in: moc)
            membership.team = team
            membership.user = self.selfUser
            return membership
        }()

        selfUser.setValue(member, forKey: #keyPath(ZMUser.membership))
        moc.saveOrRollback()
        return team
    }
    
    override func setUp() {
        super.setUp()
        MockUser.setMockSelf(self.selfUser)
        self.snapshotBackgroundColor = UIColor(white: 0, alpha: 0.8)
    }

    override func tearDown() {
        sut = nil
        MockUser.setMockSelf(nil)
        super.tearDown()
    }
    
    func testThatItRendersDefaultBar() {
        // GIVEN & WHEN
        removeTeam()
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBar() {
        // GIVEN & WHEN
        createTeam()
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarWithTeamScrolledAway() {
        // GIVEN & WHEN
        createTeam()
        self.sut = ConversationListTopBar()
        sut.contentScrollView = scrollView
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersDefaultBarAfterSpacesBar() {
        // GIVEN & WHEN
        createTeam()
        self.sut = ConversationListTopBar()

        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        removeTeam()
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

