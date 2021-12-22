//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import SnapshotTesting
import XCTest
@testable import Wire

final class GiphyConfirmationViewControllerSnapshotTests: XCTestCase {
    var sut: GiphyConfirmationViewController!

    override func setUp() {
        super.setUp()
        sut = GiphyConfirmationViewController(withZiph: nil,
                                              previewImage: nil,
                                              searchResultController: nil)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState() {
        verify(matching: sut)
    }
}
