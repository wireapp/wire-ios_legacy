//
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

/// A container for sensitive data.
///
/// `VolatileData` holds a collection of bytes that are required to exist only during the lifetime
/// of the instance. When the instance is deinitialized, the memory containing the bytes is
/// zeroed-out before being deallocated.
///
/// **Important**
///
/// Only the storage owned by an instance of `VolatileData` will be zeroed-out. Copies of the
/// `_storage` property (made by assigning its value to a variable or passing it to a function)
/// will only be zeroed-out if the copies are never written to. See: https://en.wikipedia.org/wiki/Copy-on-write

public class VolatileData {

    // MARK: - Properties

    /// The underlying storage.
    ///
    /// **Important**: assign only to a constant (with the `let` keyword) to ensure that no
    /// memory resources are duplicated.

    private(set) public var _storage: Data

    // MARK: - Life Cycle

    /// Initialize the container with the given data.

    public init(from data: Data) {
        _storage = data
    }

    deinit {
        resetBytes()
    }

    // MARK: - Methods

    /// Reset all bytes in the underlying storage to zero.

    public func resetBytes() {
        _storage.resetBytes(in: (_storage.startIndex)..<(_storage.endIndex))
    }

}
