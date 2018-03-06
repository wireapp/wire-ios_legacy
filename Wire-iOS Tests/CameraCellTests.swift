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
    var mockDeviceOrientation: MockDeviceOrientation!
    var mockCameraController: MockCameraController!

    override func setUp() {
        super.setUp()
        mockDeviceOrientation = MockDeviceOrientation()
        mockCameraController = MockCameraController()
        sut = CameraCell(frame: .zero, deviceOrientation: mockDeviceOrientation, cameraController: mockCameraController)
    }
    
    override func tearDown() {
        sut = nil
        mockDeviceOrientation = nil
        mockCameraController = nil
        super.tearDown()
    }

    func testThatDefaultSnapshotVideoOrientationIsPortrait(){
        // GIVEN
        let newCaptureVideoOrientation = sut.newCaptureVideoOrientation

        // WHEN & THEN
        XCTAssertEqual(newCaptureVideoOrientation, .portrait, "newCaptureVideoOrientation is \(String(describing: newCaptureVideoOrientation))")
    }

    func testThatNewCaptureVideoOrientationUpdatesAfterOrientationChanges(){
        // case landscapeLeft
        mockDeviceOrientation.orientation = .landscapeLeft
        XCTAssertEqual(sut.newCaptureVideoOrientation, .landscapeRight)

        // case landscapeRight
        mockDeviceOrientation.orientation = .landscapeRight
        XCTAssertEqual(sut.newCaptureVideoOrientation, .landscapeLeft)

        // case portraitUpsideDown
        mockDeviceOrientation.orientation = .portraitUpsideDown
        XCTAssertEqual(sut.newCaptureVideoOrientation, .portraitUpsideDown)

        // case portrait
        mockDeviceOrientation.orientation = .portrait
        XCTAssertEqual(sut.newCaptureVideoOrientation, .portrait)

        // default
        mockDeviceOrientation.orientation = .unknown
        XCTAssertEqual(sut.newCaptureVideoOrientation, .portrait)
    }
}
