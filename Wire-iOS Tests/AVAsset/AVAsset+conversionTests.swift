
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class AVAsset_conversionTests: XCTestCase {
    
    func testThatVideoIsConvertedToUploadFormat() {
        // GIVEN
        let videoURL = urlForResource(inTestBundleNamed: "video.mp4")

        // WHEN
        let expectation = self.expectation(description: "Video converted")

        AVAsset.convertVideoToUploadFormat(at: videoURL,
                                           deleteSourceFile: false) {url, asset, error in
            // THEN
            ///TODO: more tests
//            XCTAssertEqual(url, videoURL)
//            XCTAssertEqual((asset as? AVURLAsset)?.url, url)
            XCTAssertNotNil(url)
            XCTAssertNotNil(asset)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
}
