//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// Represents the backend API versions supported by the client.
///
/// Remove versions to drop support, add versions to add support.
/// Any changes made here are considered breaking and the compiler
/// can then be used to ensure that changes can be accounted for.

@objc
public enum APIVersion: Int32 {
    case v0 = 0
    case v1 = 1
}

// MARK: - CaseIterable

extension APIVersion: CaseIterable {}

// MARK: - Comparable

extension APIVersion: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

}
