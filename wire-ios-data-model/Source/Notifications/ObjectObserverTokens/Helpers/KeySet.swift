//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireUtilities

public enum AffectedKeys: Equatable {
    case some(KeySet)
    case all

    func combinedWith(_ other: AffectedKeys) -> AffectedKeys {
        switch (self, other) {
        case let (.some(k1), .some(k2)):
            return .some(k1.union(k2))
        default:
            return .all
        }
    }

    func containsKey(_ key: StringKeyPath) -> Bool {
        switch self {
        case let .some(keySet):
            return keySet.contains(key)
        case .all:
            return true
        }
    }
}

public func == (lhs: AffectedKeys, rhs: AffectedKeys) -> Bool {
    switch (lhs, rhs) {
    case let (.some(lk), .some(rk)):
        return lk == rk
    case (.all, .all):
        return true
    default:
        return false
    }
}

public struct KeySet: Sequence {
    public typealias Key = StringKeyPath
    public typealias Iterator = Set<StringKeyPath>.Iterator
    fileprivate let backing: Set<StringKeyPath>

    public init() {
        backing = Set()
    }

    public init(_ set: NSSet) {
        var a: [StringKeyPath] = []
        for s in set {
            if let ss = s as? String {
                a.append(StringKeyPath.keyPathForString(ss))
            } else {
                fatal("\(type(of: s)) is not a string")
            }
        }
        backing = Set(a)
    }
    public init (_ set: Set<Key>) {
        backing = set
    }

    public init (_ keys: Set<String>) {
        self.init(Array(keys))
    }

    public init(_ a: [String]) {
        var aa: [StringKeyPath] = []
        for s in a {
            aa.append(StringKeyPath.keyPathForString(s))
        }
        backing = Set<StringKeyPath>(aa)
    }
    public init(key: StringKeyPath) {
        self.init(Set([key]))
    }
    public init(keyPaths: [StringKeyPath]) {
        self.init(Set(keyPaths))
    }
    public init(key: String) {
        self.init(Set([StringKeyPath.keyPathForString(key)]))
    }
    public init(arrayLiteral elements: String...) {
        self.init(elements)
    }
    init<S: Sequence>(_ seq: S) where S.Iterator.Element == Key {
        backing = Set<Key>(seq)
    }
    public func contains(_ i: StringKeyPath) -> Bool {
        return backing.contains(i)
    }
    public func contains(_ i: String) -> Bool {
        return backing.contains(StringKeyPath.keyPathForString(i))
    }
    public func makeIterator() -> Set<StringKeyPath>.Iterator {
        return backing.makeIterator()
    }

    public var count: Int {
        return backing.count
    }
}

extension KeySet: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(backing.hashValue)
    }
}

public func == (lhs: KeySet, rhs: KeySet) -> Bool {
    return lhs.backing == rhs.backing
}

extension KeySet {
    func union(_ set: KeySet) -> KeySet {
        return KeySet(backing.union(set.backing))
    }
    func subtract(_ set: KeySet) -> KeySet {
        return KeySet(backing.subtracting(set.backing))
    }
    public var isEmpty: Bool {
        return backing.isEmpty
    }
    func filter(_ match: (StringKeyPath) -> Bool) -> KeySet {
        return KeySet(backing.filter {match($0)})
    }
}

extension KeySet: CustomDebugStringConvertible {
    public var description: String {
        let a = [StringKeyPath](backing)
        let ss = a.map { $0.rawValue }.sorted {
            (lhs, rhs) in lhs < rhs
        }
        return "KeySet {" + ss.joined(separator: " ") + "}"
    }
    public var debugDescription: String {
        return description
    }
}
