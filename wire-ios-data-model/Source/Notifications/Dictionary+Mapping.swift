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

extension Array where Element: Hashable {

    public func mapToDictionary<Value>(with block: (Element) -> Value?) -> [Element: Value] {
        var dict = [Element: Value]()
        forEach {
            if let value = block($0) {
                dict.updateValue(value, forKey: $0)
            }
        }
        return dict
    }
    public func mapToDictionaryWithOptionalValue<Value>(with block: (Element) -> Value?) -> [Element: Value?] {
        var dict = [Element: Value?]()
        forEach {
            dict.updateValue(block($0), forKey: $0)
        }
        return dict
    }
}

extension Set {

    public func mapToDictionary<Value>(with block: (Element) -> Value?) -> [Element: Value] {
        var dict = [Element: Value]()
        forEach {
            if let value = block($0) {
                dict.updateValue(value, forKey: $0)
            }
        }
        return dict
    }
}

public protocol Mergeable {
    func merged(with other: Self) -> Self
}

extension Dictionary where Value: Mergeable {

    public func merged(with other: Dictionary) -> Dictionary {
        var newDict = self
        other.forEach { (key, value) in
            newDict[key] = newDict[key]?.merged(with: value) ?? value
        }
        return newDict
    }
}
