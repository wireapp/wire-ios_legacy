//
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

import Foundation
@testable import WireSyncEngine

class URLActionTests: ZMTBaseTest {

    // MARK: Company Login

    func testThatItParsesCompanyLoginLink() throws {
        // given
        let id = UUID(uuidString: "4B1BEDB9-8899-4855-96AF-6CCED6F6F638")!
        let url = URL(string: "wire://start-sso/wire-\(id)")!

        // when
        let action = try URLAction(url: url)

        // then
        XCTAssertEqual(action, .startCompanyLogin(code: id))
    }

    func testThatItDiscardsInvalidCompanyLoginLink() {
        // given
        let url = URL(string: "wire://start-sso/wire-4B1BEDB9-8899-4855-96AF")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? ConmpanyLoginRequestError, .invalidLink)
        }
    }

    func testThatItDiscardsCompanyLoginLinkWithExtraContent() {
        // given
        let id = UUID(uuidString: "4B1BEDB9-8899-4855-96AF-6CCED6F6F638")!
        let url = URL(string: "wire://start-sso/wire-\(id)/content")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? ConmpanyLoginRequestError, .invalidLink)
        }
    }

    // MARK: - Deep link

    func testThatItParsesJoinConversationLink() throws {
        // given
        let key = "KpvjjQSDgp9aniYGUXqi"
        let code = "L6NrwRNGgsc1ekCVJoBp"
        let url = URL(string: "wire://conversation-join/?key=\(key)&code=\(code)")!

        // when
        let action = try URLAction(url: url)

        // then
        XCTAssertEqual(action, URLAction.joinConversation(key: key, code: code))
    }

    func testThatItParsesOpenConversationLink() throws {
        // given
        let uuidString = "fc43d637-6cc2-4d03-9185-2563c73d6ef2"
        let url = URL(string: "wire://conversation/\(uuidString)")!
        let uuid = UUID(uuidString: uuidString)!

        // when
        let action = try URLAction(url: url)

        // then
        XCTAssertEqual(action, URLAction.openConversation(id: uuid))
    }

    func testThatItParsesOpenUserProfileLink() throws {
        // given
        let uuidString = "fc43d637-6cc2-4d03-9185-2563c73d6ef2"
        let url = URL(string: "wire://user/\(uuidString)")!
        let uuid = UUID(uuidString: uuidString)!

        // when
        let action = try URLAction(url: url)

        // then
        XCTAssertEqual(action, URLAction.openUserProfile(id: uuid))
    }

    func testThatItDiscardsInvalidJoinConversationLink() throws {
        // given
        let key = "KpvjjQSDgp9aniYGUXqi"
        let url = URL(string: "wire://conversation-join/?key=\(key)")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? DeepLinkRequestError, .malformedLink)
        }
    }

    func testThatItDiscardsInvalidOpenUserProfileLink() {
        // given
        let url = URL(string: "wire://user/blahBlah)")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? DeepLinkRequestError, .invalidUserLink)
        }
    }

    func testThatItDiscardsInvalidOpenConversationLink() {
        // given
        let url = URL(string: "wire://conversation/foobar)")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? DeepLinkRequestError, .invalidConversationLink)
        }
    }

    func testThatItDiscardsInvalidWireURLs() {
        // given
        let url = URL(string: "wire://userx/abc/def)")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? DeepLinkRequestError, .malformedLink)
        }
    }

    func testThatItDiscardsInvalidConnectBotURLs() {
        // given
        let url = URL(string: "wire://connect/something)")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? DeepLinkRequestError, .malformedLink)
        }
    }

    func testThatItParsesValidBackendChangeURL() throws {
        // given
        let config = URL(string: "some.host/config.json")!
        let url = URL(string: "wire://access/?config=\(config)")!

        // when
        let action = try URLAction(url: url)

        // then
        XCTAssertEqual(action, URLAction.accessBackend(configurationURL: config))
    }

    func testThatItDiscardsInvalidBackendChangeURL() {
        // given

        let url = URL(string: "wire://access/?noconfig")!

        // when
        XCTAssertThrowsError(try URLAction(url: url)) { (error) in
            // then
            XCTAssertEqual(error as? DeepLinkRequestError, .malformedLink)
        }
    }

}
