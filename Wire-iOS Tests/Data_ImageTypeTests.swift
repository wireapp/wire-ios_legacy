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

///TODO: test failed with XCode11, may be due to image is not copied?
///TODO: move to utilities

final class Data_ImageTypeTests: XCTestCase {

    func testThatItIdentifiesJPEG() {

        // given
        guard let sut = #imageLiteral(resourceName: "wire-logo-shield").jpegData(compressionQuality: 1.0) else {
            XCTFail()
            return
        }

        // then
        XCTAssert(sut.isJPEG)
    }

    func testThatItDoesNotIdentifyJPEG() {

        // given
        guard let sut = #imageLiteral(resourceName: "wire-logo-shield").pngData() else {
            XCTFail()
            return
        }

        // then
        XCTAssertFalse(sut.isJPEG)
    }
}
