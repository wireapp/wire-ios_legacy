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
import WireLinkPreview

class NSDataDetectorAttachmentTests: XCTestCase {

    var detector: NSDataDetector!

    override func setUp() {
        super.setUp()
        detector = NSDataDetector.linkDetector
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - YouTube

    func testThatItDetectsYouTubeLink() {
        let text = "Such a bop! https://youtube.com/watch?v=cggNqDAtJYU"
        checkAttachments(in: text, expectation: ("https://youtube.com/watch?v=cggNqDAtJYU", .youTubeVideo))
    }

    func testThatItDetectsWWWYouTubeLink() {
        let text = "Such a bop! https://www.youtube.com/watch?v=cggNqDAtJYU"
        checkAttachments(in: text, expectation: ("https://www.youtube.com/watch?v=cggNqDAtJYU", .youTubeVideo))
    }

    func testThatItDetectsMobileYouTubeLink() {
        let text = "Such a bop! https://m.youtube.com/watch?v=cggNqDAtJYU"
        checkAttachments(in: text, expectation: ("https://m.youtube.com/watch?v=cggNqDAtJYU", .youTubeVideo))
    }

    func testThatItDetectsYouTubeShortLink() {
        let text = "Such a bop! https://youtu.be/cggNqDAtJYU"
        checkAttachments(in: text, expectation: ("https://youtu.be/cggNqDAtJYU", .youTubeVideo))
    }

    func testThatItIgnoresScamYouTubeLink() {
        let text = "Such a bop! https://scamyoutube.com/watch?v=cggNqDAtJYU"
        checkAttachments(in: text, expectation: nil)
    }

    func testThatItIgnoresSubdomainYouTubeLink() {
        let text = "Such a bop! https://preview.youtube.com/watch?v=cggNqDAtJYU"
        checkAttachments(in: text, expectation: nil)
    }

    // MARK: - Sound Cloud

    func testThatItDetectsSoundCloudTrack() {
        let text = "Wow this blew up, check out my soundcloud https://soundcloud.com/user/track"
        checkAttachments(in: text, expectation: ("https://soundcloud.com/user/track", .soundCloudTrack))
    }

    func testThatItDetectsWWWSoundCloudTrack() {
        let text = "Wow this blew up, check out my soundcloud https://www.soundcloud.com/user/track"
        checkAttachments(in: text, expectation: ("https://www.soundcloud.com/user/track", .soundCloudTrack))
    }

    func testThatItDetectsMobileSoundCloudTrack() {
        let text = "Wow this blew up, check out my soundcloud https://m.soundcloud.com/user/track"
        checkAttachments(in: text, expectation: ("https://m.soundcloud.com/user/track", .soundCloudTrack))
    }

    func testThatItDetectsSoundCloudSet() {
        let text = "Check out my playlist for the party: https://soundcloud.com/example/sets/example"
        checkAttachments(in: text, expectation: ("https://soundcloud.com/example/sets/example", .soundCloudPlaylist))
    }

    func testThatItDetectsWWWSoundCloudSet() {
        let text = "Check out my playlist for the party: https://www.soundcloud.com/example/sets/example"
        checkAttachments(in: text, expectation: ("https://www.soundcloud.com/example/sets/example", .soundCloudPlaylist))
    }

    func testThatItDetectsMobileSoundCloudSet() {
        let text = "Check out my playlist for the party: https://m.soundcloud.com/example/sets/example"
        checkAttachments(in: text, expectation: ("https://m.soundcloud.com/example/sets/example", .soundCloudPlaylist))
    }

    func testThatItIgnoresUnknownSoundCloudSubdomain() {
        let text = "Check out my playlist for the party: https://blog.soundcloud.com/example/sets/example"
        checkAttachments(in: text, expectation: nil)
    }

    func testThatItIgnoresScamSoundCloudSubdomain() {
        let text = "Check out my playlist for the party: https://scamsoundcloud.com/example/sets/example"
        checkAttachments(in: text, expectation: nil)
    }

    // MARK: - Helpers

    private func checkAttachments(in text: String, expectation: (url: String, type: LinkAttachmentType)?, file: StaticString = #file, line: UInt = #line) {
        let attachments = detector.detectLinkAttachments(in: text, excluding: [])

        if let expectation = expectation {
            guard let match = attachments[URL(string: expectation.url)!] else {
                return XCTFail("Cannot find a match for \(expectation.url)", file: file, line: line)
            }

            let expectedRange = NSRange(text.range(of: expectation.url)!, in: text)

            XCTAssertEqual(match.0, expectation.type, file: file, line: line)
            XCTAssertEqual(match.1, expectedRange, file: file, line: line)

        } else {
            XCTAssertTrue(attachments.isEmpty, "Found a match even though we didn't expect one.", file: file, line: line)
        }
    }

}
