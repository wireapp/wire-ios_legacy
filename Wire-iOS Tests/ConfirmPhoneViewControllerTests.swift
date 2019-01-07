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
@testable import Wire

final class ConfirmPhoneViewControllerTests: CoreDataSnapshotTestCase {
    
    var sut: ConfirmPhoneViewController!
    var textFieldTint: UIColor!

    override func setUp() {
        super.setUp()
        if textFieldTint == nil {
            textFieldTint = UITextField.appearance().tintColor
        }
        UITextField.appearance().tintColor = .vividRed

        sut = ConfirmPhoneViewController(newNumber: "012345678901", delegate: nil)
        sut.view.layoutIfNeeded()

        sut.view.backgroundColor = .black
        sut.view.layer.speed = 0

        sut.view.isUserInteractionEnabled = false
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()

        UITextField.appearance().tintColor = textFieldTint
    }

    func testConfirmationSentToPhoneNumber(){
        verify(view: sut.view)
    }
}
