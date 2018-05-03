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
    
    var view1 = UIView()
    var view2 = UIView()
    var view3 = UIView()
    var view4 = UIView()
    
    override func setUp() {
        super.setUp()
        
        view1.backgroundColor = .red
        view2.backgroundColor = .blue
        view3.backgroundColor = .green
        view4.backgroundColor = .yellow
        
        sut = GridView()
        snapshotBackgroundColor = .darkGray
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testGridView_oneView() {
        // Given
        sut.append(view: view1)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testGridView_twoViews() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testGridView_threeViews() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testGridView_fourViews() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        sut.append(view: view4)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
    func testGridView_threeViews_afterRemovingFirstView() {
        // Given
        sut.append(view: view1)
        sut.append(view: view2)
        sut.append(view: view3)
        sut.append(view: view4)
        sut.remove(view: view1)
        
        // Then
        verifyInIPhoneSize(view: sut)
    }
    
}
