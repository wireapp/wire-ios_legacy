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

import Foundation
@testable import Wire

class GridViewTests: ZMSnapshotTestCase {
    
    var sut: GridView!
    
    var view1: UIView!
    var view2: UIView!
    var view3: UIView!
    var view4: UIView!
    
    override func setUp() {
        super.setUp()

        view1 = UIView()
        view1.backgroundColor = .red
        view2 = UIView()
        view2.backgroundColor = .blue
        view3 = UIView()
        view3.backgroundColor = .green
        view4 = UIView()
        view4.backgroundColor = .yellow
        
        sut = GridView()
        snapshotBackgroundColor = .darkGray
    }
    
    override func tearDown() {
        sut = nil
        view1 = nil
        view2 = nil
        view3 = nil
        view4 = nil
        super.tearDown()
    }
    
    func testOneView() {
        // Given
        sut.append(view: view1)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testTwoViews() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testThreeViews() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testFourViews() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        sut.append(view: view4)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testThreeViewsAfterRemovingTopView() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        sut.append(view: view4)
        sut.remove(view: view1)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testTwoViewsAfterRemovingBottomView() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        sut.remove(view: view2)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
}
