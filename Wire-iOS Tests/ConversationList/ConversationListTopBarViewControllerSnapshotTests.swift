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

final class ConversationListTopBarViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: ConversationListTopBarViewController!
    var mockAccount: Account!

    override func setUp() {
        super.setUp()
        mockAccount = Account.mockAccount(imageData: mockImageData)

        ///TODO: inject mock user
        sut = ConversationListTopBarViewController(account: mockAccount)
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 48)

        /// TODO: remove this after snapshot is created
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        mockAccount = nil

        super.tearDown()
    }

    func testForLegalHoldEnabled(){
        verify(view: sut.view)
    }
}
