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

class StringLengthValidatorTests: XCTestCase {
    func testThatUnicode5EmojiContainsTagsPassesValidation() {
        let originalValue = "🏴󠁧󠁢󠁷󠁬󠁳󠁿"
        var value: AnyObject? = originalValue as AnyObject?
        var error: Error?

        do {
            try StringLengthValidator.validateValue(&value, minimumStringLength: 1, maximumStringLength: 64, maximumByteLength: 100)
        }
        catch let err {
            error = err
        }

        XCTAssertNil(error)
        XCTAssertEqual(originalValue, value! as! String)
    }
    
    func testThatTooShortStringsDoNotPassValidation() {
        var value: AnyObject? = "short" as AnyObject
        do {
            try StringLengthValidator.validateValue(&value,
                                                             minimumStringLength: 15,
                                                             maximumStringLength: 100,
                                                             maximumByteLength: 100)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testThatTooLongStringsDoNotPassValidation() {
        var value: AnyObject? = "long" as AnyObject
        do {
            try StringLengthValidator.validateValue(&value,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 3,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testThatValidStringsPassValidation() {
        var value: AnyObject? = "normal" as AnyObject
        do {
            try StringLengthValidator.validateValue(&value,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 10,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNil(error)
        }
        //XCTAssertTrue REsult
    }
    
    func testThatCombinedEmojiPassesValidation_3() {
        let originalValue: AnyObject? = "👨‍👧‍👦" as AnyObject
        var value = originalValue
        
        do {
            try StringLengthValidator.validateValue(&value,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 64,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNil(error)
        }
        //XCTAssertTrue REsult
        XCTAssertEqual(originalValue as! String, value as! String)
    }
    
    func testThatCombinedEmojiPassesValidation_4() {
        let originalValue: AnyObject? = "👩‍👩‍👦‍👦" as AnyObject
        var value = originalValue
        
        do {
            try StringLengthValidator.validateValue(&value,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 64,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNil(error)
        }
        //XCTAssertTrue REsult
        XCTAssertEqual(originalValue as! String, value as! String)
    }
    
    func testThatItRemovesControlCharactersBetweenCombinedEmoji() {
        let originalValue: AnyObject? = "👩‍👩‍👦‍👦/n👨‍👧‍👦" as AnyObject
        var value = originalValue
        
        do {
            try StringLengthValidator.validateValue(&value,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 64,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNil(error)
        }
        //XCTAssertTrue REsult
        XCTAssertEqual(originalValue as! String, value as! String)
    }
    
    func testThatNilIsNotValid() {
        
        var value: AnyObject? = nil
        
        do {
            try StringLengthValidator.validateValue(&value,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 10,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNotNil(error)
        }
        //XCTAssertFalse REsult
    }
    
    func testThatItReplacesNewlinesAndTabWithSpacesInThePhoneNumber() {
        
        var phoneNumber: AnyObject? = "1234\n5678" as AnyObject
        
        do {
            try StringLengthValidator.validateValue(&phoneNumber,
                                                    minimumStringLength: 0,
                                                    maximumStringLength: 20,
                                                    maximumByteLength: 100)
        } catch {
            XCTAssertNil(error)
        }
        XCTAssertEqual(phoneNumber as! String, "1234 5678")
    }
    
}
