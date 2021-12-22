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

import Foundation

extension Data {
    var isJPEG: Bool {
        let array = withUnsafeBytes { (unsafeRawBufferPointer: UnsafeRawBufferPointer) in
            [UInt8](UnsafeBufferPointer(start: unsafeRawBufferPointer.bindMemory(to: UInt8.self).baseAddress!, count: 3))
        }

        let JPEGHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
        return Array(array.prefix(JPEGHeader.count)) == JPEGHeader
    }
}
