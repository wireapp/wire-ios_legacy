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

final class MockPhotoLibrary: PhotoLibraryProtocol {
    func performChanges(_ changeBlock: @escaping () -> Void, completionHandler: ((Bool, Error?) -> Void)?) {
        changeBlock()
        completionHandler?(true, nil)
    }
}

final class MockAssetChangeRequest: AssetChangeRequestProtocol {
    static var url: URL?
    static var image: UIImage?
    
    static func creationRequestForAssetFromImage(atFileURL fileURL: URL) -> Self? {
        MockAssetChangeRequest.url = fileURL
        return .init()
    }

    static func creationRequestForAsset(from image: UIImage) -> Self {
        MockAssetChangeRequest.image = image
        return .init()
    }
}

final class MockOwner {
    var savableImage: SavableImage!
}

final class SavableImageTests: XCTestCase {
    
    weak var sut: SavableImage!
    var imageData: Data!
    var image: UIImage!

    override func setUp() {
        super.setUp()
        image = self.image(inTestBundleNamed: "transparent.png")
        imageData = image.data()

        MockAssetChangeRequest.image = nil
    }
    
    override func tearDown() {
        sut = nil
        imageData = nil
        MockAssetChangeRequest.image = nil

        super.tearDown()
    }

    func testThatSavableImageIsNotRetainedAfterSaveToLibrary() {
        autoreleasepool {
            // GIVEN
            var savableImage: SavableImage! = SavableImage(data: imageData!, isGIF: false)
            savableImage.assetChangeRequestType = MockAssetChangeRequest.self
            savableImage.photoLibrary = MockPhotoLibrary()
            savableImage.applicationType = MockApplication.self

            sut = savableImage

            // WHEN
            let expectation = self.expectation(description: "Wait for image to be saved")
            savableImage.saveToLibrary() { success in
                XCTAssert(success)
                expectation.fulfill()
                savableImage = nil
            }

            self.waitForExpectations(timeout: 2, handler: nil)

        }

        // THEN
        XCTAssertNil(sut)
    }

    func testThatImageIsSavedAfterOwnerOfSavableImageIsDealloced() {
        weak var weakMockOwner: MockOwner!
        autoreleasepool {
            // GIVEN
            var mockOwner: MockOwner! = MockOwner()
            weakMockOwner = mockOwner
            let savableImage = SavableImage(data: imageData!, isGIF: false)

            savableImage.assetChangeRequestType = MockAssetChangeRequest.self
            savableImage.photoLibrary = MockPhotoLibrary()
            savableImage.applicationType = MockApplication.self

            mockOwner.savableImage = savableImage

            sut = savableImage

            // WHEN
            let expectation = self.expectation(description: "Wait for image to be saved")
            mockOwner.savableImage.saveToLibrary() { success in
                XCTAssert(success)

                // THEN
                XCTAssertEqual(MockAssetChangeRequest.image?.size, self.image?.size)

                expectation.fulfill()

                mockOwner = nil
            }

            self.waitForExpectations(timeout: 2, handler: nil)
        }

        // THEN
        XCTAssertNil(sut)
        XCTAssertNil(weakMockOwner)
    }
}
