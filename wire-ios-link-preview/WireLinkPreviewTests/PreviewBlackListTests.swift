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

class PreviewBlackListTests: XCTestCase {

    var hosts: [String]!

    override func setUp() {
        super.setUp()
        hosts = ["soundcloud", "spotify", "youtube", "giphy", "youtu.be", "y2u.be"]
    }

    override func tearDown() {
        hosts = nil
        super.tearDown()
    }

    func testThatCorrectHostsAreAllBlacklisted() {
        for host in hosts {
            assertThatHostIsBlacklisted(host)
        }
    }

    func testThatCorrectHostsAreBlacklistedInPreviewMetadata() {
        for host in hosts {
            assertThatPreviewMetadataIsBlacklisted(host)
        }
    }

    func testThatAllowedHostsAreNotBlacklistedInPreview() {
        assertThatPreviewMetadataIsNotBlacklisted("twitter.com")
    }

    // MARK: - Helpers

    func assertThatHostIsBlacklisted(_ host: String, line: UInt = #line) {
        let url = URL(string: "www.\(host).com/example")!
        XCTAssertTrue(PreviewBlacklist.isBlacklisted(url), "\(host) was not blacklisted", line: line)
    }

    func assertThatPreviewMetadataIsBlacklisted(_ host: String, line: UInt = #line) {
        let metadata = LinkMetadata(originalURLString: "https://www.\(host).com/example", permanentURLString: "https://www.\(host).com/example", resolvedURLString: "https://www.\(host).com/example", offset: 0)
        XCTAssertTrue(metadata.isBlacklisted, line: line)
    }

    func assertThatPreviewMetadataIsNotBlacklisted(_ host: String, line: UInt = #line) {
        let metadata = LinkMetadata(originalURLString: "https://www.\(host).com/example", permanentURLString: "https://www.\(host).com/example", resolvedURLString: "https://www.\(host).com/example", offset: 0)
        XCTAssertFalse(metadata.isBlacklisted, line: line)
    }

}
