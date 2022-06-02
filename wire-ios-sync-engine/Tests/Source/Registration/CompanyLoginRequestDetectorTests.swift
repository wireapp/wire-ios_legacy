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
@testable import WireSyncEngine

class CompanyLoginRequestDetectorTests: XCTestCase {

    var pasteboard: MockPasteboard!
    var detector: CompanyLoginRequestDetector!

    override func setUp() {
        super.setUp()
        pasteboard = MockPasteboard()
        detector = CompanyLoginRequestDetector(pasteboard: pasteboard)
    }

    override func tearDown() {
        detector = nil
        pasteboard = nil
        super.tearDown()
    }

    func testThatItDetectsValidWireCode_Uppercase() {
        // GIVEN
        pasteboard.text = "wire-46A17D7F-2351-495E-AEDA-E7C96AC74994"

        // WHEN
        var detectedCode: String?
        let detectionExpectation = expectation(description: "Detector returns a result")

        detector.detectCopiedRequestCode {
            detectedCode = $0?.code
            detectionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        // THEN
        XCTAssertEqual(detectedCode, "wire-46A17D7F-2351-495E-AEDA-E7C96AC74994")
    }

    func testThatItDetectsValidWireCode_Lowercase() {
        // GIVEN
        pasteboard.text = "wire-70488875-13dd-4ba7-9636-a983e1831f5f"

        // WHEN
        var detectedCode: String?
        let detectionExpectation = expectation(description: "Detector returns a result")

        detector.detectCopiedRequestCode {
            detectedCode = $0?.code
            detectionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        // THEN
        XCTAssertEqual(detectedCode, "wire-70488875-13DD-4BA7-9636-A983E1831F5F")
    }

    func testThatItDetectsCodeInComplexText() {
        // GIVEN
        pasteboard.text = """
        <html>
            This is your code: ohwowwire-A6AAA905-E42D-4220-A455-CFE8822DB690&nbsp;
        </html>
        """

        // WHEN
        var detectedCode: String?
        let detectionExpectation = expectation(description: "Detector returns a result")

        detector.detectCopiedRequestCode {
            detectedCode = $0?.code
            detectionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        // THEN
        XCTAssertEqual(detectedCode, "wire-A6AAA905-E42D-4220-A455-CFE8822DB690")
    }

    func testThatItDetectsValidCode_UserInput() {
        // GIVEN
        let text = "wire-81DD91BA-B3D0-46F0-BC29-E491938F0A54"

        // WHEN
        let isDetectedCodeValid = CompanyLoginRequestDetector.isValidRequestCode(in: text)

        // THEN
        XCTAssertTrue(isDetectedCodeValid)
    }

    func testThatItDetectsInvalidCode_MissingPrefix() {
        // GIVEN
        pasteboard.text = "8FBF187C-2039-409B-B16F-5FCF485514E1"

        // WHEN
        var detectedCode: String?
        let detectionExpectation = expectation(description: "Detector returns a result")

        detector.detectCopiedRequestCode {
            detectedCode = $0?.code
            detectionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        // THEN
        XCTAssertNil(detectedCode)
    }

    func testThatItDetectsInvalidCode_WrongUUIDFormat() {
        // GIVEN
        pasteboard.text = "wire-D82916EA"

        // WHEN
        var detectedCode: String?
        let detectionExpectation = expectation(description: "Detector returns a result")

        detector.detectCopiedRequestCode {
            detectedCode = $0?.code
            detectionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        // THEN
        XCTAssertNil(detectedCode)
    }

    func testThatItFailsWhenPasteboardIsEmpty() {
        // GIVEN
        pasteboard.text = nil

        // WHEN
        var detectedCode: String?
        let detectionExpectation = expectation(description: "Detector returns a result")

        detector.detectCopiedRequestCode {
            detectedCode = $0?.code
            detectionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        // THEN
        XCTAssertNil(detectedCode)
    }

    func testThatItSetsIsNewOnTheResultIfTheCodeHasChanged() {
        // GIVEN
        let code = "wire-81DD91BA-B3D0-46F0-BC29-E491938F0A54"
        pasteboard.text = code

        do {
            let detectionExpectation = expectation(description: "Detector returns a result")

            detector.detectCopiedRequestCode {
                XCTAssertEqual($0?.isNew, true)
                XCTAssertEqual($0?.code, code)
                detectionExpectation.fulfill()
            }

            waitForExpectations(timeout: 1, handler: nil)
        }

        do {
            let detectionExpectation = expectation(description: "Detector returns a result")

            detector.detectCopiedRequestCode {
                XCTAssertEqual($0?.isNew, false)
                XCTAssertEqual($0?.code, code)
                detectionExpectation.fulfill()
            }

            waitForExpectations(timeout: 1, handler: nil)
        }

        // WHEN
        let changedCode = "wire-81DD91BA-B3D0-46F0-BC29-E491938F0A55"
        pasteboard.text = changedCode

        // THEN
        do {
            let detectionExpectation = expectation(description: "Detector returns a result")

            detector.detectCopiedRequestCode {
                XCTAssertEqual($0?.isNew, true)
                XCTAssertEqual($0?.code, changedCode)
                detectionExpectation.fulfill()
            }

            waitForExpectations(timeout: 1, handler: nil)
        }
    }

    func testThatItDoesNotSetIsNewOnTheResultIfTheCodeHasChanged() {
        // GIVEN
        let code = "wire-81DD91BA-B3D0-46F0-BC29-E491938F0A54"
        pasteboard.text = code

        // WHEN
        do {
            let detectionExpectation = expectation(description: "Detector returns a result")

            detector.detectCopiedRequestCode {
                XCTAssertEqual($0?.isNew, true)
                XCTAssertEqual($0?.code, code)
                detectionExpectation.fulfill()
            }

            waitForExpectations(timeout: 1, handler: nil)
        }

        // WHEN
        do {
            let detectionExpectation = expectation(description: "Detector returns a result")

            detector.detectCopiedRequestCode {
                XCTAssertEqual($0?.isNew, false)
                XCTAssertEqual($0?.code, code)
                detectionExpectation.fulfill()
            }

            waitForExpectations(timeout: 1, handler: nil)
        }

        // THEN
        do {
            let detectionExpectation = expectation(description: "Detector returns a result")

            detector.detectCopiedRequestCode {
                XCTAssertEqual($0?.isNew, false)
                XCTAssertEqual($0?.code, code)
                detectionExpectation.fulfill()
            }

            waitForExpectations(timeout: 1, handler: nil)
        }
    }

    func testThatParseReturnsSSOCodeCaseIfInputIsSSO() {
        // GIVEN
        let code = "wire-81DD91BA-B3D0-46F0-BC29-E491938F0A54"
        var valuesEqual: Bool = false

        // WHEN
        let result = CompanyLoginRequestDetector.parse(input: code)
        if case CompanyLoginRequestDetector.ParserResult.ssoCode = result {
            valuesEqual = true
        }

        // THEN
        XCTAssertTrue(valuesEqual)
    }

    func testThatParseReturnsDomainCaseIfInputIsEmail() {
        // GIVEN
        let email = "bob@wire.com"
        var valuesEqual: Bool = false
        var resultDomain: String?

        // WHEN
        let result = CompanyLoginRequestDetector.parse(input: email)
        if case CompanyLoginRequestDetector.ParserResult.domain(let domain) = result {
            resultDomain = domain
            valuesEqual = true
        }

        // THEN
        XCTAssertTrue(valuesEqual)
        XCTAssertNotNil(resultDomain)
        XCTAssertEqual(resultDomain, "wire.com")
    }

    func testThatParseReturnsUnknownCaseIfInputIsInvalid() {
        // GIVEN
        let input = "123pho567"
        var valuesEqual: Bool = false

        // WHEN
        let result = CompanyLoginRequestDetector.parse(input: input)
        if case CompanyLoginRequestDetector.ParserResult.unknown = result {
            valuesEqual = true
        }

        // THEN
        XCTAssertTrue(valuesEqual)
    }
}
