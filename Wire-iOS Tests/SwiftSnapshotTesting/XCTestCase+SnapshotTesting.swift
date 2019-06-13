//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import SnapshotTesting
@testable import Wire

extension XCTestCase {
    func snapshotDirectory(file: StaticString = #file) -> String {
        let fileName = "\(file)"
        let path = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent

        return path
    }

    func verify(matching value: UIAlertController,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: .image,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file, testName: testName, line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

    func verify(matching value: UIViewController,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: .image,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file, testName: testName, line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

    func verify(matching value: UIView,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: .image,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file, testName: testName, line: line)

        XCTAssertNil(failure, file: file, line: line)
    }


    func verify<Value, Format>(matching value: Value,
                               as snapshotting: Snapshotting<Value, Format>,
                               file: StaticString = #file,
                               testName: String = #function,
                               line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: snapshotting,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }
}

extension Snapshotting where Value == UIAlertController, Format == UIImage {

    /// A snapshot strategy for comparing UIAlertController views based on pixel equality.
    /// Compare UIAlertController.view to prevert the view is resized to fix the default UIViewController.view's size
    public static var image: Snapshotting<UIAlertController, UIImage> {
        return Snapshotting<UIView, UIImage>.image(precision: 1, size: nil).pullback { $0.view }
    }
}

// MARK: - color scheme
extension XCTestCase {
    func resetColorScheme() {
        ColorScheme.default.variant = .light

        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }
}
