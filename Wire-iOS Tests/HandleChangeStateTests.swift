//
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

class HandleChangeStateTests: XCTestCase {
    
    // MARK: Validation Fail Tests
    
    func testFunctionThatHandleIsTooShort() {
        let handleChangeState = HandleChangeState(currentHandle: "testUser",
                                                  newHandle: "testUser",
                                                  availability: .unknown)
        XCTAssertThrowsError(try handleChangeState.validate("t")) { error in
            XCTAssertEqual(error as! HandleChangeState.ValidationError,
                           HandleChangeState.ValidationError.tooShort)
        }
    }
    
    func testFunctionThatHandleIsTooLong() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertThrowsError(try handleChangeState.validate("testusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestusertestuser1")) { error in
            XCTAssertEqual(error as! HandleChangeState.ValidationError,
                           HandleChangeState.ValidationError.tooLong)
        }
    }
    
    func testFunctionThatHandleIsSameAsPrevious() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertThrowsError(try handleChangeState.validate("testuser")) { error in
            XCTAssertEqual(error as! HandleChangeState.ValidationError,
                           HandleChangeState.ValidationError.sameAsPrevious)
        }
    }
    
    func testFunctionThatHandleIsInvalidCharacterForUpperCaseChar() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertThrowsError(try handleChangeState.validate("TestUser")) { error in
            XCTAssertEqual(error as! HandleChangeState.ValidationError,
                           HandleChangeState.ValidationError.invalidCharacter)
        }
    }
    
    func testFunctionThatHandleIsInvalidCharacter() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertThrowsError(try handleChangeState.validate("testuser:testuser")) { error in
            XCTAssertEqual(error as! HandleChangeState.ValidationError,
                           HandleChangeState.ValidationError.invalidCharacter)
        }
    }
    
    // MARK: Validation Success Tests
    
    func testFunctionThatDoNotHandleForUnderscoreChar() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertNoThrow(try handleChangeState.validate("testuser_testuser"))
    }
    
    func testFunctionThatDoNotHandleForDotChar() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertNoThrow(try handleChangeState.validate("testuser.testuser"))
    }
    
    func testFunctionThatDoNotHandleForDashChar() {
        let handleChangeState = HandleChangeState(currentHandle: "testuser",
                                                  newHandle: "testuser",
                                                  availability: .unknown)
        XCTAssertNoThrow(try handleChangeState.validate("testuser-testuser"))
    }
}
