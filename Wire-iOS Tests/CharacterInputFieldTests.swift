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

import XCTest
@testable import Wire

final class TestCharacterInputFieldDelegate: NSObject, CharacterInputFieldDelegate {
    var shouldAccept = true
    func shouldAcceptChanges(_ inputField: CharacterInputField) -> Bool {
        return shouldAccept
    }

    var didChangeText: [String] = []
    func didChangeText(_ inputField: CharacterInputField, to: String) {
        didChangeText.append(to)
    }
    var didFillInput: Int = 0
    func didFillInput(inputField: CharacterInputField, text: String) {
        didFillInput = didFillInput + 1
    }
}


final class CharacterInputFieldTests: XCTestCase {
    var sut: CharacterInputField! = nil
    var delegate: TestCharacterInputFieldDelegate! = nil

    override func setUp() {
        super.setUp()
        sut = CharacterInputField(maxLength: 8, characterSet: CharacterSet.decimalDigits, size: CGSize(width: 375, height: 56))
        delegate = TestCharacterInputFieldDelegate()
        sut.delegate = delegate
    }

    override func tearDown() {
        sut.removeFromSuperview()
        sut = nil
        delegate = nil
        super.tearDown()
    }

    func testThatItCanBecomeFirstResponder() {
        // when
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sut)
        // then
        XCTAssertTrue(sut.canBecomeFocused)
        XCTAssertTrue(sut.becomeFirstResponder())
        XCTAssertTrue(sut.isFirstResponder)
    }

    func testThatItSupportsPaste() {
        XCTAssertTrue(sut.canPerformAction(#selector(UIControl.paste(_:)), withSender: nil))
    }

    func testThatItIgnoresInputWhenDelegateSaysItShouldNotAcceptInput() {
        // given
        XCTAssertEqual(delegate.didChangeText, [])

        // when
        delegate.shouldAccept = false
        sut.insertText("1")

        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "")
    }

    func testThatItIgnoresDeleteWhenDelegateSaysItShouldNotAcceptInput() {
        // given
        let text = "12"
        sut.text = text
        XCTAssertEqual(delegate.didChangeText, [])

        // when
        delegate.shouldAccept = false
        sut.deleteBackward()

        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, text)
    }


    func testThatItDoesNotCallDelegateForSettingTextDirectly() {
        // when
        sut.text = "1234"
        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "1234")
        XCTAssertEqual(sut.accessibilityValue, "1234")
        XCTAssertFalse(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 0)
    }

    func testThatItAppendsOneSymbolAndCallsDelegate() {
        // when
        sut.insertText("1")
        // then
        XCTAssertEqual(delegate.didChangeText, ["1"])
        XCTAssertEqual(sut.text, "1")
        XCTAssertEqual(sut.accessibilityValue, "1")
        XCTAssertFalse(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 0)
    }

    func testThatItDeletesSymbolAndCallsDelegate() {
        // given
        sut.text = "1234"
        // when
        sut.deleteBackward()
        // then
        XCTAssertEqual(delegate.didChangeText, ["123"])
        XCTAssertEqual(sut.text, "123")
        XCTAssertEqual(sut.accessibilityValue, "123")
        XCTAssertFalse(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 0)
    }

    func testThatItDoesNotDeleteWhenNoSymbols() {
        // given
        sut.text = ""
        // when
        sut.deleteBackward()
        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "")
        XCTAssertEqual(sut.accessibilityValue, "")
        XCTAssertFalse(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 0)
    }

    func testThatItAllowsToPasteAndCallsDelegate() {
        // given
        sut.text = "1234"
        UIPasteboard.general.string = "567"
        // when
        sut.paste(nil)
        // then
        XCTAssertEqual(delegate.didChangeText, ["567"])
        XCTAssertEqual(sut.text, "567")
        XCTAssertEqual(sut.accessibilityValue, "567")
        XCTAssertFalse(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 0)
    }

    func testThatItForbidsIncompatibleCharacters() {
        sut.text = "1234"
        // when
        sut.insertText("V")
        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "1234")
        XCTAssertEqual(sut.accessibilityValue, "1234")
        XCTAssertFalse(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 0)
    }

    func testThatItAllowsEnteringCharactersUpToMax() {
        // when
        sut.insertText("123456789")
        // then
        XCTAssertEqual(delegate.didChangeText, ["12345678"])
        XCTAssertEqual(sut.text, "12345678")
        XCTAssertEqual(sut.accessibilityValue, "12345678")
        XCTAssertTrue(sut.isFilled)
        XCTAssertEqual(delegate.didFillInput, 1)
    }

    func testThatItWorksWithOtherSymbols() {
        // given
        let sut = CharacterInputField(maxLength: 100, characterSet: CharacterSet.uppercaseLetters, size: CGSize(width: 375, height: 56))
        sut.delegate = delegate
        // when
        sut.insertText("123456789")
        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "")

        // when
        sut.insertText("HELLOWORLD")

        // then
        XCTAssertEqual(delegate.didChangeText, ["HELLOWORLD"])
        XCTAssertEqual(sut.text, "HELLOWORLD")
        XCTAssertEqual(delegate.didFillInput, 0)
    }
}

final class CharacterInputFieldScreenshotTests: XCTestCase {
    var sut: CharacterInputField! = nil

    override func setUp() {
        super.setUp()
        let size = CGSize(width: 375, height: 56)
        sut = CharacterInputField(maxLength: 8, characterSet: CharacterSet.decimalDigits, size: size)

        sut.frame = CGRect(origin: .zero, size: size)
    }

    override func tearDown() {
        sut.removeFromSuperview()
        sut = nil
        super.tearDown()
    }

    func testDefaultState() {
        // then
        verify(matching: sut)
    }

    func testFocusedState() {
        // given
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sut)

        // when
        sut.becomeFirstResponder()

        // then
        verify(matching: sut)
    }

    func testFocusedDeFocusedState() {
        // given
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sut)

        // when
        sut.becomeFirstResponder()
        sut.resignFirstResponder()

        // then
        verify(matching: sut)
    }

    func testOneCharacterState() {
        // when
        sut.insertText("1")

        // then
        verify(matching: sut)
    }

    func testAllCharactersEnteredState() {
        // when
        sut.insertText("12345678")

        // then
        verify(matching: sut)
    }
}
