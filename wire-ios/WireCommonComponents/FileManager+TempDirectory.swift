// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension FileManager {
    static public func createTmpDirectory(fileName: String? = nil) throws -> URL {
        let fileManager = FileManager.default
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName ?? UUID().uuidString) // temp subdir
        if !fileManager.fileExists(atPath: tmp.absoluteString) {
            try fileManager.createDirectory(at: tmp, withIntermediateDirectories: true)
        }

        return tmp
    }

    public func removeTmpIfNeededAndCopy(fileURL: URL, tmpURL: URL) throws {
        if fileExists(atPath: tmpURL.path) {
                try FileManager.default.removeItem(at: tmpURL)
        }

        try copyItem(at: fileURL, to: tmpURL)

    }
}
