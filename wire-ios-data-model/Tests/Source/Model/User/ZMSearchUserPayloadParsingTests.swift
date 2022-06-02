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
@testable import WireDataModel

class ZMSearchUserPayloadParsingTests: ZMBaseManagedObjectTest {

    func testThatItParsesTheBasicPayload() {
        // given
        let uuid = UUID()
        let domain = "foo.bar"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "qualified_id": [
                                        "id": uuid.transportString(),
                                        "domain": domain
                                      ]]

        // when
        let user = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!

        // then
        XCTAssertEqual(user.name, "A user that was found")
        XCTAssertEqual(user.handle, "@user")
        XCTAssertEqual(user.domain, domain)
        XCTAssertEqual(user.remoteIdentifier, uuid)
        XCTAssertEqual(user.accentColorValue, ZMAccentColor.init(rawValue: 5))
        XCTAssertFalse(user.isServiceUser)
        XCTAssertTrue(user.canBeConnected)
    }

    func testThatItParsesService_ProviderIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "summary": "Short summary",
                                      "provider": provider.transportString()]

        // when
        let user = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!

        // then
        XCTAssertTrue(user.isServiceUser)
        XCTAssertEqual(user.summary, "Short summary")
        XCTAssertEqual(user.providerIdentifier, provider.transportString())
        XCTAssertEqual(user.serviceIdentifier, uuid.transportString())
        XCTAssertFalse(user.canBeConnected)
    }

    func testThatItParsesService_ImageIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]

        // when
        let searchUser = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!

        // then
        XCTAssertEqual(searchUser.assetKeys?.preview, assetKey)
    }

    func testThatItParsesService_IgnoresOtherImageIdentifier() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "full",
                                                  "key": assetKey]]]

        // when
        let searchUser = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!

        // then
        XCTAssertNil(searchUser.assetKeys)
    }

    func testThatCachedSearchUserIsReturnedFromPayloadConstructor() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]

        let searchUser1 = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!

        // when
        let searchUser2 = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!

        // then
        XCTAssertNotNil(searchUser2)
        XCTAssertEqual(searchUser1, searchUser2)
    }

    func testThatCachedSearchUserIsUpdatedWithLocalUser() throws {
        // given
        let uuid = UUID()
        let provider = UUID()
        let assetKey = "1234567890-ASSET-KEY"
        let payload: [String: Any] = ["name": "A user that was found",
                                      "handle": "@user",
                                      "accent_id": 5,
                                      "id": uuid.transportString(),
                                      "provider": provider.transportString(),
                                      "assets": [["type": "image",
                                                  "size": "preview",
                                                  "key": assetKey]]]

        let searchUser1 = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)!
        XCTAssertNil(searchUser1.user)

        let localUser = ZMUser.insertNewObject(in: uiMOC)
        localUser.remoteIdentifier = uuid

        // when
        let searchUser2 = ZMSearchUser.searchUser(from: payload, contextProvider: self.coreDataStack)

        // then
        XCTAssertNotNil(searchUser2)
        XCTAssertEqual(searchUser1, searchUser2)
        XCTAssertEqual(searchUser2?.user, localUser)
    }
}
