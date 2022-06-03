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

import Foundation

extension Sequence {
    public func map<Value>(_ keyPath: KeyPath<Element, Value>) -> [Value] {
        return map { $0[keyPath: keyPath] }
    }

    public func flatMap<Value>(_ keyPath: KeyPath<Element, [Value]>) -> [Value] {
        return flatMap { $0[keyPath: keyPath] }
    }

    public func compactMap<Value>(_ keyPath: KeyPath<Element, Value?>) -> [Value] {
        return compactMap { $0[keyPath: keyPath] }
    }

    public func filter(_ keyPath: KeyPath<Element, Bool>) -> [Element] {
        return filter { $0[keyPath: keyPath] }
    }

    public func any(_ keyPath: KeyPath<Element, Bool>) -> Bool {
        return any { $0[keyPath: keyPath] }
    }

    public  func all(_ keyPath: KeyPath<Element, Bool>) -> Bool {
        return all { $0[keyPath: keyPath] }
    }
}


extension Optional {
    public func map<Value>(_ keyPath: KeyPath<Wrapped, Value>) -> Value? {
        return map { $0[keyPath: keyPath] }
    }

    public func flatMap<Value>(_ keyPath: KeyPath<Wrapped, Value?>) -> Value? {
        return flatMap { $0[keyPath: keyPath] }
    }
}
