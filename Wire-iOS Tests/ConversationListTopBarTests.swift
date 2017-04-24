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

class ConversationListTopBarTests: ZMSnapshotTestCase {
    let sut = ConversationListTopBar()
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        scrollView.contentSize = CGSize(width: 320, height: 800)
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        return scrollView
    }()
    
    func createWorkSpaces(createFamily: Bool = false) {
        let workspaceName = "W"
        
        var spaces: [Space] = []
        
        let privateSpace: Space = {
            let selfUser = ZMUser.selfUser()
            
            var image: UIImage? = .none
            
            if let imageData = selfUser?.imageMediumData {
                image = UIImage(from: imageData, withMaxSize: 100)
            }
            
            let predicate = NSPredicate(format: "NOT (displayName CONTAINS[cd] %@)", workspaceName)
            let privateSpace = Space(name: selfUser?.displayName ?? "", image: image, predicate: predicate)
            privateSpace.selected = true
            return privateSpace
        }()

        spaces.append(privateSpace)
        
        let workSpace: Space = {
            let predicate = NSPredicate(format: "displayName CONTAINS[cd] %@", workspaceName)
            let workSpace = Space(name: workspaceName, image: UIImage(named: "wire-logo-shield"), predicate: predicate)
            workSpace.selected = true
            return workSpace
        }()
        
        spaces.append(workSpace)
        
        if createFamily {
            let familySpace: Space = {
                let predicate = NSPredicate(format: "displayName CONTAINS[cd] %@", workspaceName)
                let workSpace = Space(name: "Family", image: UIImage(named: "wire-logo-shield"), predicate: predicate)
                workSpace.selected = true
                return workSpace
            }()
            
            spaces.append(familySpace)
        }
        
        Space.spaces = spaces
    }
    
    override func setUp() {
        super.setUp()
        sut.contentScrollView = scrollView
        self.snapshotBackgroundColor = UIColor(white: 0, alpha: 0.8)
    }
    
    func testThatItRendersDefaultBar() {
        // GIVEN & WHEN
        sut.setShowSpaces(to: false)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBar() {
        // GIVEN & WHEN
        createWorkSpaces()
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarScrolledAway() {
        // GIVEN & WHEN
        createWorkSpaces()
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarThreeSpaces() {
        // GIVEN & WHEN
        createWorkSpaces(createFamily: true)
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarThreeSpacesScrolledAway() {
        // GIVEN & WHEN
        createWorkSpaces(createFamily: true)
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarOneSelected() {
        // GIVEN & WHEN
        createWorkSpaces()
        Space.spaces.first!.selected = false
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarOneSelectedScrolledAway() {
        // GIVEN & WHEN
        createWorkSpaces()
        Space.spaces.first!.selected = false
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.collapsed)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarAfterDefaultBar() {
        // GIVEN & WHEN
        createWorkSpaces()
        sut.setShowSpaces(to: false)
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersSpacesBarAfterDefaultBar_ScrolledAway() {
        // GIVEN & WHEN
        createWorkSpaces()
        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        sut.setShowSpaces(to: false)
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        sut.setShowSpaces(to: true)
        
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersDefaultBarAfterSpacesBar() {
        // GIVEN & WHEN
        createWorkSpaces()
        sut.setShowSpaces(to: true)
        sut.update(to: ConversationListTopBar.ImagesState.visible)
        
        // WHEN
        _ = sut.snapshotView()
        
        // AND WHEN
        sut.setShowSpaces(to: false)
        
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

