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

import Foundation
import WireDataModel

extension ZMUser {

    func setV3PictureIdentifiers() {
        previewProfileAssetIdentifier = UUID.create().transportString()
        completeProfileAssetIdentifier = UUID.create().transportString()
    }
}

class UserImageLocalCacheTests: BaseZMMessageTests {

    var testUser: ZMUser!
    var sut: UserImageLocalCache!

    override func setUp() {
        super.setUp()
        testUser = ZMUser.insertNewObject(in: self.uiMOC)
        testUser.remoteIdentifier = UUID.create()

        sut = UserImageLocalCache(location: nil)
    }

    override func tearDown() {
        testUser = nil
        sut = nil
        super.tearDown()
    }

    func testThatItHasNilData() {
        XCTAssertNil(sut.userImage(testUser, size: .preview))
        XCTAssertNil(sut.userImage(testUser, size: .complete))
    }

    func testThatPersistedDataCanBeRetrievedAsynchronously() {
        // given
        testUser.setV3PictureIdentifiers()
        let largeData = "LARGE".data(using: .utf8)!
        let smallData = "SMALL".data(using: .utf8)!

        // when
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)
        sut = UserImageLocalCache(location: nil)

        // then
        let previewImageArrived = expectation(description: "Preview image arrived")
        let completeImageArrived = expectation(description: "Complete image arrived")
        sut.userImage(testUser, size: .preview, queue: .global()) { (smallDataResult) in
            XCTAssertEqual(smallDataResult, smallData)
            previewImageArrived.fulfill()
        }

        sut.userImage(testUser, size: .complete, queue: .global()) { (largeDataResult) in
            XCTAssertEqual(largeDataResult, largeData)
            completeImageArrived.fulfill()
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}

// MARK: - Storing
extension UserImageLocalCacheTests {
    func testThatItHasNilDataWhenNotSetForV3() {
        testUser.setV3PictureIdentifiers()
        XCTAssertNil(sut.userImage(testUser, size: .preview))
        XCTAssertNil(sut.userImage(testUser, size: .complete))
    }

    func testThatItSetsSmallAndLargeUserImageForV3() {

        // given
        testUser.setV3PictureIdentifiers()
        let largeData = "LARGE".data(using: .utf8)!
        let smallData = "SMALL".data(using: .utf8)!

        // when
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)

        // then
        XCTAssertEqual(sut.userImage(testUser, size: .complete), largeData)
        XCTAssertEqual(sut.userImage(testUser, size: .preview), smallData)

    }

    func testThatItPersistsSmallAndLargeUserImageForV3() {

        // given
        testUser.setV3PictureIdentifiers()
        let largeData = "LARGE".data(using: .utf8)!
        let smallData = "SMALL".data(using: .utf8)!

        // when
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)
        sut = UserImageLocalCache(location: nil)

        // then
        XCTAssertEqual(sut.userImage(testUser, size: .complete), largeData)
        XCTAssertEqual(sut.userImage(testUser, size: .preview), smallData)
    }

}

// MARK: - Retrieval
extension UserImageLocalCacheTests {

    func testThatItReturnsV3AssetsWhenPresent() {
        // given
        let largeData = "LARGE".data(using: .utf8)!
        let smallData = "SMALL".data(using: .utf8)!

        // when
        testUser.setV3PictureIdentifiers()
        XCTAssertNil(sut.userImage(testUser, size: .complete))
        XCTAssertNil(sut.userImage(testUser, size: .preview))
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)

        // then
        XCTAssertEqual(sut.userImage(testUser, size: .complete), largeData)
        XCTAssertEqual(sut.userImage(testUser, size: .preview), smallData)
    }

}

// MARK: - Removal
extension UserImageLocalCacheTests {
    func testThatItRemovesAllImagesFromCache() {
        // given
        testUser.setV3PictureIdentifiers()
        sut.setUserImage(testUser, imageData: "baz".data(using: .utf8)!, size: .complete)
        sut.setUserImage(testUser, imageData: "moo".data(using: .utf8)!, size: .preview)

        // when
        sut.removeAllUserImages(testUser)

        // then
        XCTAssertNil(sut.userImage(testUser, size: .complete))
        XCTAssertNil(sut.userImage(testUser, size: .preview))
    }
}
