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
import SnapshotTesting
import XCTest
@testable import Wire

class GridViewTests: XCTestCase {
    
    var sut: GridView!
    var views: [UIView]!
    
    override func setUp() {
        super.setUp()
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: XCTestCase.DeviceSizeIPhone5)
        
        let colors: [UIColor] = [
            .red,
            .blue,
            .cyan,
            .brown,
            .orange,
            .green,
            .yellow,
            .magenta,
            .purple,
            .systemPink,
            .systemTeal,
            .gray
        ]
        
        views = [UIView]()
        for index in 0...11 {
            let view = UIView(frame: frame)
            view.backgroundColor = colors[index]
            views.append(view)
        }
        
        sut = GridView()
        sut.frame = frame
    }
    
    override func tearDown() {
        sut = nil
        views = nil
        super.tearDown()
    }
    
    func appendViews(_ amount: Int) {
        guard amount > 0 else { return }
        
        for index in 0...amount-1 {
            sut.append(view: views[index])
        }
    }
    
    func testGrid(withAmount amount: Int,
                  file: StaticString = #file,
                  testName: String = #function,
                  line: UInt = #line) {
        // Given
        appendViews(amount)
        
        // Then
        verify(matching: sut, file: file, testName: testName, line: line)
    }
    
    func testOneView() {
        testGrid(withAmount: 1)
    }
    
    func testTwoViews() {
        testGrid(withAmount: 2)
    }
    
    func testThreeViews() {
        testGrid(withAmount: 3)
    }
    
    func testFourViews() {
        testGrid(withAmount: 4)
    }

    func testSixViews() {
        testGrid(withAmount: 6)
    }
    
    func testEightViews() {
        testGrid(withAmount: 8)
    }
    
    func testTenViews() {
        testGrid(withAmount: 10)
    }
    
    func testTwelveViews() {
        testGrid(withAmount: 12)
    }
    
    func testThreeViewsAfterRemovingTopView() {
        // Given
        appendViews(4)
        sut.remove(view: views[0])
        
        // Then
        verify(matching: sut)
    }
    
    func testTwoViewsAfterRemovingBottomView() {
        // Given
        appendViews(3)
        sut.remove(view: views[2])
        
        // Then
        verify(matching: sut)
    }
}
