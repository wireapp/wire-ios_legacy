//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import XCTest
import Cartography
@testable import Wire

class TestCharacterInputFieldDelegate: NSObject, CharacterInputFieldDelegate {
    var didChangeText: [String] = []
    func didChangeText(_ inputField: CharacterInputField, to: String) {
        didChangeText.append(to)
    }
}


final class CharacterInputFieldTests: XCTestCase {
    var sut: CharacterInputField! = nil
    var delegate: TestCharacterInputFieldDelegate! = nil
    
    override func setUp() {
        super.setUp()
        sut = CharacterInputField(maxLength: 8, characterSet: CharacterSet.decimalDigits)
        delegate = TestCharacterInputFieldDelegate()
        sut.delegate = delegate
    }
    
    override func tearDown() {
        super.tearDown()
        sut.removeFromSuperview()
        sut = nil
        delegate = nil
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
    
    func testThatItDoesNotCallDelegateForSettingTextDirectly() {
        // when
        sut.text = "1234"
        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "1234")
        XCTAssertFalse(sut.isFilled)
    }
    
    func testThatItAppendsOneSymbolAndCallsDelegate() {
        // when
        sut.insertText("1")
        // then
        XCTAssertEqual(delegate.didChangeText, ["1"])
        XCTAssertEqual(sut.text, "1")
        XCTAssertFalse(sut.isFilled)
    }
    
    func testThatItDeletesSymbolAndCallsDelegate() {
        // given
        sut.text = "1234"
        // when
        sut.deleteBackward()
        // then
        XCTAssertEqual(delegate.didChangeText, ["123"])
        XCTAssertEqual(sut.text, "123")
        XCTAssertFalse(sut.isFilled)
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
        XCTAssertFalse(sut.isFilled)
    }
    
    func testThatItForbidsIncompatibleCharacters() {
        sut.text = "1234"
        // when
        sut.insertText("V")
        // then
        XCTAssertEqual(delegate.didChangeText, [])
        XCTAssertEqual(sut.text, "1234")
        XCTAssertFalse(sut.isFilled)
    }
    
    func testThatItAllowsEnteringCharactersUpToMax() {
        // when
        sut.insertText("123456789")
        // then
        XCTAssertEqual(delegate.didChangeText, ["12345678"])
        XCTAssertEqual(sut.text, "12345678")
        XCTAssertTrue(sut.isFilled)
    }
    
    func testThatItWorksWithOtherSymbols() {
        // given
        let sut = CharacterInputField(maxLength: 100, characterSet: CharacterSet.uppercaseLetters)
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
    }
}

final class CharacterInputFieldScreenshotTests: ZMSnapshotTestCase {
    var sut: CharacterInputField! = nil
    
    override func setUp() {
        super.setUp()
        sut = CharacterInputField(maxLength: 8, characterSet: CharacterSet.decimalDigits)
    }
    
    override func tearDown() {
        super.tearDown()
        sut.removeFromSuperview()
        sut = nil
    }
    
    func testDefaultState() {
        // then
        verify(view: sut.snapshotView())
    }
    
    func testFocusedState() {
        // given
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sut)

        // when
        sut.becomeFirstResponder()
        
        // then
        verify(view: sut.snapshotView())
    }
    
    func testFocusedDeFocusedState() {
        // given
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sut)
        
        // when
        sut.becomeFirstResponder()
        sut.resignFirstResponder()
        
        // then
        verify(view: sut.snapshotView())
    }
    
    func testOneCharacterState() {
        // when
        sut.insertText("1")
        
        // then
        verify(view: sut.snapshotView())
    }
    
    func testAllCharactersEnteredState() {
        // when
        sut.insertText("12345678")
        
        // then
        verify(view: sut.snapshotView())
    }
}

fileprivate extension UIView {
    func snapshotView() -> UIView {
        let topView = UIApplication.shared.keyWindow!.rootViewController!.view!
            
        topView.addSubview(self)

        constrain(self, topView) { selfView, topView in
            selfView.center == topView.center
        }
        
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}

