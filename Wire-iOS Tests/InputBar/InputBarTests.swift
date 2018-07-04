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


import XCTest
import Cartography
@testable import Wire
import Classy

class InputBarTests: ZMSnapshotTestCase {
    
    let shortText = "Lorem ipsum dolor"
    let longText = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est"
    let LTRText = "ناك حقيقة مثبتة منذ"
    
    let buttons = { () -> [UIButton] in
        let b1 = IconButton()
        b1.setIcon(.paperclip, with: .tiny, for: UIControlState())
        
        let b2 = IconButton()
        b2.setIcon(.photo, with: .tiny, for: UIControlState())
        
        let b3 = IconButton()
        b3.setIcon(.brush, with: .tiny, for: UIControlState())
        
        let b4 = IconButton()
        b4.setIcon(.ping, with: .tiny, for: UIControlState())

        return [b1, b2, b3, b4]
    }

    var sut: InputBar!

    override func setUp() {
        super.setUp()
        sut = InputBar(buttons: buttons())
        sut.leftAccessoryView.isHidden = true
        sut.rightAccessoryStackView.isHidden = true
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.layer.speed = 0
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }
    
    func testNoText() {
        sut.textView.text = ""
        sut.updateFakeCursorVisibility()
        sut.leftAccessoryView.isHidden = true
        sut.rightAccessoryStackView.isHidden = true
        CASStyler.default().styleItem(sut)
        
        verifyInAllPhoneWidths(view: sut)
    }
    
    func testShortText() {
        sut.textView.text = shortText
        sut.updateFakeCursorVisibility()
        CASStyler.default().styleItem(sut)
        
        verifyInAllPhoneWidths(view: sut)
    }
    
    func testLongText() {
        sut.textView.text = longText
        sut.updateFakeCursorVisibility()
        CASStyler.default().styleItem(sut)
        
        verifyInAllPhoneWidths(view: sut)
        verifyInAllTabletWidths(view: sut)
    }
    
    func testRTLText() {
        sut.textView.text = LTRText
        sut.textView.textAlignment = .right
        sut.updateFakeCursorVisibility()
        CASStyler.default().styleItem(sut)
        
        verifyInAllPhoneWidths(view: sut)
        verifyInAllTabletWidths(view: sut)
    }
    
    func testButtonsWithTitle() {
        let buttonsWithText = buttons()
        
        for button in buttonsWithText {
            button.setTitle("NEW", for: UIControlState())
            button.titleLabel!.font = UIFont.systemFont(ofSize: 8, weight: .semibold)
            button.setTitleColor(UIColor.red, for: UIControlState())
        }
        
        let inputBar = InputBar(buttons: buttonsWithText)
        inputBar.leftAccessoryView.isHidden = true
        inputBar.rightAccessoryStackView.isHidden = true

        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.default().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
    }
    
    func testButtonsWrapsWithEllipsis() {
        let inputBar = InputBar(buttons: buttons() + buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.leftAccessoryView.isHidden = true
        inputBar.rightAccessoryStackView.isHidden = true
        inputBar.textView.text = ""
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.default().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
    }
    
    func testEphemeralMode() {
        sut.textView.text = ""
        sut.updateFakeCursorVisibility()
        sut.setInputBarState(.writing(ephemeral: .message), animated: false)
        sut.updateEphemeralState()
        CASStyler.default().styleItem(sut)
        
        verifyInAllPhoneWidths(view: sut)
    }

    func testEphemeralModeWithMarkdown() {
        sut.textView.text = ""
        sut.updateFakeCursorVisibility()
        sut.setInputBarState(.markingDown(ephemeral: .message), animated: false)
        sut.updateEphemeralState()
        CASStyler.default().styleItem(sut)

        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersCorrectlyInEditState() {
        sut.setInputBarState(.editing(originalText: "This text is being edited"), animated: false)
        sut.updateFakeCursorVisibility()
        CASStyler.default().styleItem(sut)
        verifyInAllPhoneWidths(view: sut)
    }
    
    func testThatItRendersCorrectlyInEditState_LongText() {
        sut.setInputBarState(.editing(originalText: longText), animated: false)

        sut.updateFakeCursorVisibility()
        CASStyler.default().styleItem(sut)
        verifyInAllPhoneWidths(view: sut)
    }

}
