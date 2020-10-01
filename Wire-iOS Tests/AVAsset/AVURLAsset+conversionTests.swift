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

final class AVURLAsset_conversionTests: XCTestCase {

    func testThatVideoIsConvertedToUploadFormat() {
        // GIVEN
        let videoURL = urlForResource(inTestBundleNamed: "video.mp4")
        let originalAsset: AVURLAsset = AVURLAsset(url: videoURL, options: nil)

        // WHEN
        let expectation = self.expectation(description: "Video converted")

        AVURLAsset.convertVideoToUploadFormat(at: videoURL,
                                              quality: AVAssetExportPresetLowQuality,
                                              deleteSourceFile: false) {
                                                url, asset, error in
                                                // THEN

                                                // exported file URL
                                                XCTAssertEqual(url?.lastPathComponent, videoURL.lastPathComponent)
                                                // temp asset URL for upload
                                                XCTAssertEqual(asset?.url.lastPathComponent, videoURL.lastPathComponent)
                                                XCTAssertEqual(asset?.duration, originalAsset.duration)
                                                // converted file with low quality should be smaller
                                                XCTAssertLessThan(url!.fileSize!, videoURL.fileSize!)

                                                XCTAssertNil(error)
                                                expectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
}
