//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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


extension String {
    func resolvingEmoticonShortcuts(configuration: EmoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration.sharedInstance) -> String {
        let mutableString = NSMutableString(string: self)

        mutableString.resolveEmoticonShortcuts(in: NSRange(location: 0, length: count), configuration: configuration)

        return String(mutableString)
    }

    mutating func resolveEmoticonShortcuts(in range: NSRange,
                                           configuration: EmoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration.sharedInstance) {
        let mutableString = NSMutableString(string: self)

        mutableString.resolveEmoticonShortcuts(in: range, configuration: configuration)

        self = String(mutableString)
    }
}

final class NSString_EmoticonSubstitutionTests: XCTestCase {

    var sut: EmoticonSubstitutionConfiguration!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }


    func testThatAllEmoticonSubstitutionForNonMockedConfigurationWorks() {
        // Given
        let targetString = "😊😊😄😄😀😀😎😎😎😞😞😉😉😉😉😕😛😛😛😛😜😜😜😜😮😮😇😇😇😇😏😠😠😡😈😈😈😈😢😢😢😂😂😘😘😘😐😐😳😶😶😶😶🙌❤💔"
        let string = ":):-):D:-D:d:-dB-)b-)8-):(:-(;);-);-];]:-/:P:-P:p:-p;P;-P;p;-p:o:-oO:)O:-)o:)o:-);^):-||:@>:(}:-)}:)3:-)3:):'-(:'(;(:'-):'):*:^*:-*:-|:|:$:-X:X:-#:#\\o/<3</3"

        // When
        let resolvedString = string.resolvingEmoticonShortcuts()

        // Then
        XCTAssertEqual(resolvedString, targetString)
    }

    func testThatSimpleSubstitutionWorks() {
        // Given
        let targetString = "Hello, my darling!😊 I love you <3!"

        let testString = "Hello, my darling!:) I love you <3!"

        sut = createEmoticonSubstitutionConfiguration(fileName: "emo-test-01.json")

        // When
        let resolvedString = testString.resolvingEmoticonShortcuts(configuration: sut)

        // Then
        XCTAssertEqual(resolvedString, targetString)
    }


    func testThatSubstitutionInSpecificRangeWorks() {
        // Given
        let targetString = "Hello, my darling!😊 I love you <3!"

        let testString = "Hello, my darling!:) I love you <3!"
        var resolvedString = testString

        sut = createEmoticonSubstitutionConfiguration(fileName: "emo-test-03.json")

        // When
        resolvedString.resolveEmoticonShortcuts(in: NSRange(location: 0, length: 22), configuration: sut)

        // Then
        XCTAssertEqual(resolvedString, targetString)
    }

    func testThatSubstitutionInTailRangeWorks() {
        // Given
        let targetString = "<3 Lorem Ipsum Dolor 😈Ame😊 😊"

        sut = createEmoticonSubstitutionConfiguration(fileName: "emo-test-03.json")

        let testString = "<3 Lorem Ipsum Dolor }:-)Ame:) :)"
        var resolvedString = testString

        // When
        resolvedString.resolveEmoticonShortcuts(in: NSRange(location: 20, length: 13), configuration: sut)

        // Then
        XCTAssertEqual(resolvedString, targetString)
    }

    func testThatSubstitutionInMiddleRangeWorks() {
        // Given
        let targetString = "Hello, my darling!😊 I love you <3!"

        sut = createEmoticonSubstitutionConfiguration(fileName: "emo-test-03.json")

        let testString = "Hello, my darling!:) I love you <3!"
        var resolvedString = testString

        // When
        resolvedString.resolveEmoticonShortcuts(in: NSRange(location: 10, length: 22), configuration: sut)

        // Then
        XCTAssertEqual(resolvedString, targetString)
    }
}
