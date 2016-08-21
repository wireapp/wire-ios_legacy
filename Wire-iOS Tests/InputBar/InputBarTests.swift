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

class InputBarTests: ZMSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        self.accentColor = .VividRed
    }
    
    let shortText = "Lorem ipsum dolor"
    let longText = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est"
    let LTRText = "ناك حقيقة مثبتة منذ"
    
    let buttons = { () -> [UIButton] in
        let b1 = IconButton()
        b1.setIcon(.Paperclip, withSize: .Tiny, forState: .Normal)
        
        let b2 = IconButton()
        b2.setIcon(.Photo, withSize: .Tiny, forState: .Normal)
        
        let b3 = IconButton()
        b3.setIcon(.Brush, withSize: .Tiny, forState: .Normal)
        
        let b4 = IconButton()
        b4.setIcon(.Ping, withSize: .Tiny, forState: .Normal)

        return [b1, b2, b3, b4]
    }
    
    func testNoText() {
        let inputBar = InputBar(buttons: buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.text = ""
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
    }
    
    func testShortText() {
        let inputBar = InputBar(buttons: buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.text = shortText
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
    }
    
    func testLongText() {
        let inputBar = InputBar(buttons: buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.text = longText
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
        verifyInAllTabletWidths(view: inputBar)
    }
    
    func testRTLText() {
        let inputBar = InputBar(buttons: buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.text = LTRText
        inputBar.textView.textAlignment = .Right
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
        verifyInAllTabletWidths(view: inputBar)
    }
    
    func testButtonsWithTitle() {
        let buttonsWithText = buttons()
        
        for button in buttonsWithText {
            button.setTitle("NEW", forState: .Normal)
            button.titleLabel!.font = UIFont.systemFontOfSize(8, weight: UIFontWeightSemibold)
            button.setTitleColor(UIColor.redColor(), forState: .Normal)
        }
        
        let inputBar = InputBar(buttons: buttonsWithText)
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
    }
    
    func testButtonsWrapsWithElipsis() {
        let inputBar = InputBar(buttons: buttons() + buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.text = ""
        inputBar.layer.speed = 0
        inputBar.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(inputBar)
        
        verifyInAllPhoneWidths(view: inputBar)
    }

    // Disabled until we figure out the `[MockUser conversationType]` crash after resetting the simulator / on CI
    func disabled_testThatItRendersCorrectlyInEditState() {
        let sut = InputBar(buttons: buttons())
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.layer.speed = 0
        sut.updateInputBar(withState: .Editing(originalText: "This text is being edited"), animated: false)
        sut.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(sut)
        verifyInAllPhoneWidths(view: sut)
    }
    
    func disabled_testThatItRendersCorrectlyInEditState_LongText() {
        let sut = InputBar(buttons: buttons())
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.layer.speed = 0
        sut.updateInputBar(withState: .Editing(originalText: longText), animated: false)

        sut.updateFakeCursorVisibility()
        CASStyler.defaultStyler().styleItem(sut)
        verifyInAllPhoneWidths(view: sut)
    }

}
