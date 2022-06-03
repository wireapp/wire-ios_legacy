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

final class FunctionOperatorTests: XCTestCase {

    func testThaItNegatesABooleanTestFunction() {
        // given
        let foo: (Bool) -> Bool = { return $0 }
        
        // when
        let negated = !foo
        
        // then
        XCTAssert(foo(true))
        XCTAssert(negated(false))
        XCTAssertFalse(negated(true))
    }

}
