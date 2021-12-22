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
import WireCommonComponents
@testable import Wire

private final class MockBackupExcluder: BackupExcluder {}

final class BackupExcluderTests: XCTestCase { /// TODO: test protocol instead
    private var sut: MockBackupExcluder!
    let filename = "test.txt"

    override func setUp() {
        super.setUp()

        delete(fileNamed: filename)
        sut = MockBackupExcluder()
    }

    override func tearDown() {
        sut = nil
        delete(fileNamed: filename)

        super.tearDown()
    }

    func delete(fileNamed: String) {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        let file = URL(fileURLWithPath: path).appendingPathComponent(fileNamed)

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: file)
    }

    func write(text: String, to fileNamed: String) {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        let file = URL(fileURLWithPath: path).appendingPathComponent(fileNamed)
        try? text.write(to: file, atomically: false, encoding: String.Encoding.utf8)
    }

    func testThatFileIsExcluded() {
        /// GIVEN
        let filesToExclude: [FileInDirectory] = [(FileManager.SearchPathDirectory.documentDirectory, filename)]

        write(text: "test", to: filename)

        filesToExclude.forEach { (directory, path) in
            let url = URL.directory(for: directory).appendingPathComponent(path)

            XCTAssertFalse(url.isExcludedFromBackup)
        }

        /// WHEN
        try! MockBackupExcluder.exclude(filesToExclude: filesToExclude)

        /// THEN
        filesToExclude.forEach { (directory, path) in
            let url = URL.directory(for: directory).appendingPathComponent(path)

            XCTAssert(url.isExcludedFromBackup)
        }

    }
}
