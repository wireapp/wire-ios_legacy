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

final class NSString_EmoticonSubstitutionTests: XCTestCase {
    
    //    var sut: NSString_EmoticonSubstitutionTestsTests!

    override func setUp() {
        super.setUp()
        //        sut = NSString_EmoticonSubstitutionTestsTests()
    }
    
    override func tearDown() {
        //        sut = nil
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
        let fileName = "emo-test-01.json"
        let path = urlForResource(inTestBundleNamed: fileName).path

        let emoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration(configurationFile:path)!

        let testString = "Hello, my darling!:) I love you <3!"

        // When
        let resolvedString = testString.resolvingEmoticonShortcuts(configuration: emoticonSubstitutionConfiguration)

        // Then
        XCTAssertEqual(resolvedString, targetString)
    }

}

