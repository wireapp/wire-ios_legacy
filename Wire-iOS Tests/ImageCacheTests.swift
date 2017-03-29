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
import XCTest
@testable import Wire


class ImageCacheTests: XCTestCase {
    var sut = ImageCache(name: "TestImageCache")
    var imageData = try! Data(contentsOf: Bundle(for: ImageCacheTests.self).url(forResource: "unsplash_matterhorn", withExtension: "jpg")!)
    
    func testThatItLeavesGroupWhenProcessingOneImage() {
        // GIVEN
        var imagesProcessed = 0
        let groupNotifyExpectation = self.expectation(description: "Group done")
        
        self.sut.image(for: imageData, cacheKey: "key", creationBlock: {
            return UIImage(data: $0)! as Any
        }) { _ in
            imagesProcessed = imagesProcessed + 1
        }
        
        // WHEN
        self.sut.processingGroup.notify(qos: DispatchQoS.default, flags: [], queue: .main) {
            groupNotifyExpectation.fulfill()
        }
        
        // THEN
        self.waitForExpectations(timeout: 5) {
            XCTAssertNil($0)
        }
        XCTAssertEqual(imagesProcessed, 1)
    }
    
    func testThatItLeavesGroupWhenProcessingManyImages() {
        // GIVEN
        let imagesToProcess = 5
        var imagesProcessed = 0
        let groupNotifyExpectation = self.expectation(description: "Group done")
        
        for index in 1...imagesToProcess {
            self.sut.image(for: imageData, cacheKey: "key\(index)", creationBlock: {
                return UIImage(data: $0)! as Any
            }) { _ in
                imagesProcessed = imagesProcessed + 1
            }
        }
        
        // WHEN
        self.sut.processingGroup.notify(qos: DispatchQoS.default, flags: [], queue: .main) {
            groupNotifyExpectation.fulfill()
        }
        
        // THEN
        self.waitForExpectations(timeout: 5) {
            XCTAssertNil($0)
        }
        XCTAssertEqual(imagesProcessed, imagesToProcess)
    }
    
    func testThatItLeavesGroupAfterLeavingItOnce() {
        // GIVEN
        var imagesProcessed = 0
        let groupNotifyExpectation = self.expectation(description: "Group done once")
        
        self.sut.image(for: imageData, cacheKey: "key1", creationBlock: {
            return UIImage(data: $0)! as Any
        }) { _ in
            imagesProcessed = imagesProcessed + 1
        }
        
        // WHEN
        self.sut.processingGroup.notify(qos: DispatchQoS.default, flags: [], queue: .main) {
            groupNotifyExpectation.fulfill()
        }
        
        // THEN
        self.waitForExpectations(timeout: 15) {
            XCTAssertNil($0)
        }
        XCTAssertEqual(imagesProcessed, 1)
        
        // AND WHEN
        self.sut.image(for: imageData, cacheKey: "key2", creationBlock: {
            return UIImage(data: $0)! as Any
        }) { _ in
            imagesProcessed = imagesProcessed + 1
        }
        
        let secondGroupNotifyExpectation = self.expectation(description: "Group done twice")
        
        self.sut.processingGroup.notify(qos: DispatchQoS.default, flags: [], queue: .main) {
            secondGroupNotifyExpectation.fulfill()
        }
        
        // THEN
        self.waitForExpectations(timeout: 5) {
            XCTAssertNil($0)
        }
        XCTAssertEqual(imagesProcessed, 2)
    }
    
    func testThatItLeavesGroupWhenTwoCallbacksForOneTask() {
        // GIVEN
        var imagesProcessedCallbacks = 0
        let groupNotifyExpectation = self.expectation(description: "Group done")
        
        self.sut.image(for: imageData, cacheKey: "key", creationBlock: {
            return UIImage(data: $0)! as Any
        }) { _ in
            imagesProcessedCallbacks = imagesProcessedCallbacks + 1
        }
        
        self.sut.image(for: imageData, cacheKey: "key", creationBlock: {
            return UIImage(data: $0)! as Any
        }) { _ in
            imagesProcessedCallbacks = imagesProcessedCallbacks + 1
        }
        
        // WHEN
        self.sut.processingGroup.notify(qos: DispatchQoS.default, flags: [], queue: .main) {
            groupNotifyExpectation.fulfill()
        }
        
        // THEN
        self.waitForExpectations(timeout: 5) {
            XCTAssertNil($0)
        }
        XCTAssertEqual(imagesProcessedCallbacks, 2)
    }
    
    func testThatItLeavesGroupWhenNoImagesProcessed() {
        // GIVEN
        let groupNotifyExpectation = self.expectation(description: "Group done")
        
        // WHEN
        self.sut.processingGroup.notify(qos: DispatchQoS.default, flags: [], queue: .main) {
            groupNotifyExpectation.fulfill()
        }
        
        // THEN
        self.waitForExpectations(timeout: 5) {
            XCTAssertNil($0)
        }
    }
}
