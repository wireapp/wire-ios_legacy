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

extension AVCaptureVideoOrientation : CustomStringConvertible {
    public var description: String {
        switch self {
        case .portrait : return "portrait"

        case .portraitUpsideDown : return "portraitUpsideDown"

        case .landscapeRight : return "landscapeRight"

        case .landscapeLeft : return "landscapeLeft"
        }
    }
}

final class CameraCellTests: XCTestCase {
    
    var sut: CameraCell!
    var mockDeviceOrientation: MockDeviceOrientation! = MockDeviceOrientation()
    var mockCameraController: MockCameraController! = MockCameraController()

    override func setUp() {
        super.setUp()
        sut = CameraCell(frame: .zero, deviceOrientation: mockDeviceOrientation, cameraController: mockCameraController)
    }
    
    override func tearDown() {
        sut = nil
        mockDeviceOrientation = nil
        super.tearDown()
    }



    /// Example checker method which can be reused in different tests
    ///
    /// - Parameters:
    ///   - file: optional, for XCTAssert logging error source
    ///   - line: optional, for XCTAssert logging error source
    fileprivate func checkerExample(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(true, file: file, line: line)
    }

    func testExample(){
        // GIVEN
        mockDeviceOrientation.orientation = .portrait
        sut.deviceOrientationDidChange(nil)
        let snapshotVideoOrientation = sut.cameraController?.snapshotVideoOrientation
        XCTAssertEqual(snapshotVideoOrientation, .portrait, "snapshotVideoOrientation is \(String(describing: snapshotVideoOrientation))")

        // WHEN

        // THEN
    }
}
