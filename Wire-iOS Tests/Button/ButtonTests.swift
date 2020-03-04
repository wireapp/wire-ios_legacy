
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import SnapshotTesting

final class ButtonTests: XCTestCase {
    var sut: Button!

    override func setUp() {
        sut = Button(style: .empty)
        sut.setTitle("Dummy button", for: .normal)
    }

    override func tearDown() {
        sut = nil
    }
    
    func testForStyleChangedToFull() {
        //GIVEN
        
        //WHEN
        sut.style = .full
        
        //THEN
        verify(matching: sut)
    }

    func testForStyleChangedToEmpty() {
        //GIVEN
        
        //WHEN
        sut.style = .full
        sut.style = .empty

        //THEN
        verify(matching: sut)
    }
}
