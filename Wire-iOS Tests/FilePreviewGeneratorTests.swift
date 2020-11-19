//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireCommonComponents
@testable import Wire

import MobileCoreServices

final class FilePreviewGeneratorTests : XCTestCase {
    func testThatItDoesNotBreakOn0x0PDF() {
        // given
        let pdfPath = Bundle(for: type(of: self)).path(forResource: "0x0", ofType: "pdf")!
        let sut = PDFFilePreviewGenerator(callbackQueue: OperationQueue.main, thumbnailSize: CGSize(width: 100, height: 100))
        // when
        let expectation = self.expectation(description: "Finished generating the preview")
        sut.generatePreview(URL(fileURLWithPath: pdfPath), UTI: kUTTypePDF as String) { image in
            XCTAssertNil(image)
            expectation.fulfill()
        }
        // then
        
        ///TODO: try
        ///let delayExpectation = XCTestExpectation()
//        delayExpectation.isInverted = true
//        wait(for: [delayExpectation], timeout: 5)
        ///TODO: crash
//        This method waits on expectations created with XCTestCase’s convenience methods only. This method does not wait on expectations created manually through initializers on XCTestExpectation or its subclasses.
//        To wait for manually created expectations, use the wait(for:timeout:) or wait(for:timeout:enforceOrder:) methods, or the corresponding methods on XCTWaiter, passing an explicit list of expectations.
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testThatItDoesNotBreakOnHugePDF() {
        // given
        let pdfPath = Bundle(for: type(of: self)).path(forResource: "huge", ofType: "pdf")!
        let sut = PDFFilePreviewGenerator(callbackQueue: OperationQueue.main, thumbnailSize: CGSize(width: 100, height: 100))
        // when
        let expectation = self.expectation(description: "Finished generating the preview")
        sut.generatePreview(URL(fileURLWithPath: pdfPath), UTI: kUTTypePDF as String) { image in
            XCTAssertNil(image)
            expectation.fulfill()
        }
        // then
        self.waitForExpectations(timeout: 2, handler: nil)
    }
}
