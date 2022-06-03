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

import XCTest
import UniformTypeIdentifiers
import CoreServices
@testable import WireUtilities

final class UTIHelperTests: XCTestCase {

    func testThatConformsToVectorTypeIdentifiesSVG() {
        // given, when, then
        XCTAssert(UTIHelper.conformsToVectorType(uti: "public.svg-image"))
    }

    func testThatConformsTypeIdentifiesJSONIsNotImageOrVectorType() {
        // given
        let sut = "public.json"

        // when & then
        XCTAssertFalse(UTIHelper.conformsToImageType(uti: sut))
        XCTAssertFalse(UTIHelper.conformsToVectorType(uti: sut))

        XCTAssert(UTIHelper.conformsToJsonType(uti: sut))
    }

    func testThatConformsMovieType() {
        // given
        let sut = "video/mp4"

        // when & then
        XCTAssertFalse(UTIHelper.conformsToImageType(uti: sut))
        XCTAssertFalse(UTIHelper.conformsToVectorType(uti: sut))

        XCTAssert(UTIHelper.conformsToMovieType(mime: sut))
    }

    func testThatQuickTimeMovieConformsMovieType() {
        // given
        let sut = "video/quicktime"

        // when & then
        XCTAssert(UTIHelper.conformsToMovieType(mime: sut))
    }

    func testThatCommonFilesConformsAudioType() {
        // given
        let suts = ["audio/mp4",
                    "audio/mpeg",
                    "audio/x-m4a"]

        suts.forEach { sut in
            // when & then
            XCTAssert(UTIHelper.conformsToAudioType(mime: sut), "\(sut) does not conform to audio type")
        }
    }

    func testThatConformsToImageTypeIdentifiesCommonImageTypes() {
        // given
        let suts = ["public.jpeg",
                    "com.compuserve.gif",
                    "public.png",
                    "public.svg-image"]

        suts.forEach { sut in
            // when & then
            XCTAssert(UTIHelper.conformsToImageType(uti: sut), "\(sut) does not conform to image type")
        }
    }

    func testThatConvertToUtiConvertsCommonImageTypes() {

        // given & when & then
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/jpeg"), "public.jpeg")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/gif"), "com.compuserve.gif")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/png"), "public.png")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/svg+xml"), "public.svg-image")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "video/mp4"), "public.mpeg-4")
    }

    func testThatConvertToMimeConvertsCommonImageTypes() {
        // given & when & then
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.jpeg"), "image/jpeg")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "com.compuserve.gif"), "image/gif")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.png"), "image/png")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.svg-image"), "image/svg+xml")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.mpeg-4"), "video/mp4")

    }

    func testThatConvertToMimeConvertsFileExtensions() {
        XCTAssertEqual(UTIHelper.convertToMime(fileExtension: "pkpass"), "application/vnd.apple.pkpass")
        XCTAssertEqual(UTIHelper.convertToMime(fileExtension: "txt"), "text/plain")
        XCTAssertEqual(UTIHelper.convertToMime(fileExtension: "mp4"), "video/mp4")
    }

    func testThatConvertToFileExtensionHandlesCommonTypes() {
        XCTAssertEqual(UTIHelper.convertToFileExtension(mime: "application/vnd.apple.pkpass"), "pkpass")
        XCTAssertEqual(UTIHelper.convertToFileExtension(mime: "video/mp4"), "mp4")
        XCTAssertEqual(UTIHelper.convertToFileExtension(mime: "text/plain"), "txt")
    }
}
