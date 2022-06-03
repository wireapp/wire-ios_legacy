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


public extension IteratorProtocol {

    mutating func any(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        guard let current = next() else { return false }
        return try predicate(current) || any(predicate)
    }

    mutating func all(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        guard let current = next() else { return true }
        return try predicate(current) && all(predicate)
    }

}


public extension Sequence {
    func any(_ predicate: (Iterator.Element) throws -> Bool) rethrows -> Bool {
        var iterator = makeIterator()
        return try iterator.any(predicate)
    }

     func all(_ predicate: (Iterator.Element) throws -> Bool) rethrows -> Bool {
        var iterator = makeIterator()
        return try iterator.all(predicate)
    }
}
