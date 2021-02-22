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
@testable import Wire

final class InputBarTests: ZMSnapshotTestCase {

    let shortText = "Lorem ipsum dolor"
    let longText = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est"
    let LTRText = "ناك حقيقة مثبتة منذ"

    let buttons = { () -> [UIButton] in
        let b1 = IconButton()
        b1.setIcon(.paperclip, size: .tiny, for: [])

        let b2 = IconButton()
        b2.setIcon(.photo, size: .tiny, for: [])

        let b3 = IconButton()
        b3.setIcon(.brush, size: .tiny, for: [])

        let b4 = IconButton()
        b4.setIcon(.ping, size: .tiny, for: [])

        return [b1, b2, b3, b4]
    }

    var sut: InputBar!

    override func setUp() {
        super.setUp()

        sut = InputBar(buttons: buttons())
        sut.leftAccessoryView.isHidden = true
        sut.rightAccessoryStackView.isHidden = true

        sut.textView.text = ""
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    //MARK: - placeholder

    func testNoText() {
        verifyInAllPhoneWidths(view: sut)
    }

    func testUserIsAvailable() {
        let mockUser = MockUser.mockUsers()!.first!
        mockUser.availability = .available

        sut.availabilityPlaceholder = AvailabilityStringBuilder.string(for: mockUser, with: .placeholder, color: sut.placeholderColor)

        verifyInAllPhoneWidths(view: sut)
    }

    //MARK: - Text inputted

    func testShortText() {
        sut.textView.text = shortText


        verifyInAllPhoneWidths(view: sut)
    }

    func testLongText() {
        sut.textView.text = longText

        verifyInAllPhoneWidths(view: sut)
        verifyInAllTabletWidths(view: sut)
    }

    func testRTLText() {
        sut.textView.text = LTRText
        sut.textView.textAlignment = .right


        verifyInAllPhoneWidths(view: sut)
        verifyInAllTabletWidths(view: sut)
    }

    func testTruncatedMention() {
        guard let userWithLongName = MockUser.realMockUsers()?.last else { return XCTFail() }
        userWithLongName.name = "Matt loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong name"
        let text = "Hello @\(userWithLongName.name!)"
        sut.textView.setText(text, withMentions: [Mention(range: (text as NSString).range(of: "@\(userWithLongName.name!)"), user: userWithLongName)])
        verifyInAllPhoneWidths(view: sut)
        verifyInAllTabletWidths(view: sut)
    }

    func testButtonsWithTitle() {
        let buttonsWithText = buttons()

        for button in buttonsWithText {
            button.setTitle("NEW", for: [])
            button.titleLabel!.font = UIFont.systemFont(ofSize: 8, weight: .semibold)
            button.setTitleColor(UIColor.red, for: [])
        }

        let inputBar = InputBar(buttons: buttonsWithText)
        inputBar.leftAccessoryView.isHidden = true
        inputBar.rightAccessoryStackView.isHidden = true

        inputBar.translatesAutoresizingMaskIntoConstraints = false

        verifyInAllPhoneWidths(view: inputBar)
    }

    func testButtonsWrapsWithEllipsis() {
        let inputBar = InputBar(buttons: buttons() + buttons())
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.leftAccessoryView.isHidden = true
        inputBar.rightAccessoryStackView.isHidden = true
        inputBar.textView.text = ""

        verifyInAllPhoneWidths(view: inputBar)
    }

    func testEphemeralMode() {
        sut.textView.text = ""
        sut.setInputBarState(.writing(ephemeral: .message), animated: false)
        sut.updateEphemeralState()


        verifyInAllPhoneWidths(view: sut)
    }

    func testEphemeralModeWithMarkdown() {
        sut.textView.text = ""
        sut.setInputBarState(.markingDown(ephemeral: .message), animated: false)
        sut.updateEphemeralState()

        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersCorrectlyInEditState() {
        sut.setInputBarState(.editing(originalText: "This text is being edited", mentions: []), animated: false)
        sut.textView.resignFirstResponder() // make sure to avoid cursor being visible

        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersCorrectlyInEditState_LongText() {
        sut.setInputBarState(.editing(originalText: longText, mentions: []), animated: false)

        sut.textView.resignFirstResponder() // make sure to avoid cursor being visible

        verifyInAllPhoneWidths(view: sut)
    }
}
