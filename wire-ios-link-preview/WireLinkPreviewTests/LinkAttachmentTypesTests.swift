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
@testable import WireLinkPreview

class LinkAttachmentTypesTests: XCTestCase {

    func testThatItEncodesAndDecodesWithNSCoder() {
        // GIVEN
        let youtube = LinkAttachment(type: .youTubeVideo, title: "iPhone X - Reveal", permalink: URL(string: "https://www.youtube.com/watch?v=sRIQsy2PGyM")!,
                                     thumbnails: [URL(string: "https://i.ytimg.com/vi/sRIQsy2PGyM/maxresdefault.jpg")!], originalRange: NSRange(location: 10, length: 43))

        // WHEN
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: youtube)
        let decodedAttachment = NSKeyedUnarchiver.unarchiveObject(with: encodedData) as? LinkAttachment

        // THEN
        XCTAssertEqual(decodedAttachment?.type, .youTubeVideo)
        XCTAssertEqual(decodedAttachment?.title, "iPhone X - Reveal")
        XCTAssertEqual(decodedAttachment?.permalink, URL(string: "https://www.youtube.com/watch?v=sRIQsy2PGyM")!)
        XCTAssertEqual(decodedAttachment?.thumbnails, [URL(string: "https://i.ytimg.com/vi/sRIQsy2PGyM/maxresdefault.jpg")!])
        XCTAssertEqual(decodedAttachment?.originalRange, NSRange(location: 10, length: 43))
    }

    func testThatItDecodesYouTubeFromOpenGraph() {
        // GIVEN
        let openGraphData = OpenGraphData(title: "iPhone X - Reveal", type: "video.other", url: "https://www.youtube.com/watch?v=sRIQsy2PGyM", resolvedURL: "https://www.youtube.com/watch?v=sRIQsy2PGyM", imageUrls: ["https://i.ytimg.com/vi/sRIQsy2PGyM/maxresdefault.jpg"])

        // WHEN
        let decodedAttachment = LinkAttachment(openGraphData: openGraphData, detectedType: .youTubeVideo, originalRange: NSRange(location: 10, length: 43))

        // THEN
        XCTAssertEqual(decodedAttachment?.type, .youTubeVideo)
        XCTAssertEqual(decodedAttachment?.title, "iPhone X - Reveal")
        XCTAssertEqual(decodedAttachment?.permalink, URL(string: "https://www.youtube.com/watch?v=sRIQsy2PGyM")!)
        XCTAssertEqual(decodedAttachment?.thumbnails, [URL(string: "https://i.ytimg.com/vi/sRIQsy2PGyM/maxresdefault.jpg")!])
        XCTAssertEqual(decodedAttachment?.originalRange, NSRange(location: 10, length: 43))
    }

}
