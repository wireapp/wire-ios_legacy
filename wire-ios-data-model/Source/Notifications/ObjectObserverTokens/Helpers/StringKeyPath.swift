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

/// A key path (as in key-value-coding).
public final class StringKeyPath: Hashable {

    public let rawValue: String
    public let count: Int

    static private var KeyPathCache: [String: StringKeyPath] = [:]

    public class func keyPathForString(_ string: String) -> StringKeyPath {

        if let keyPath = KeyPathCache[string] {
            return keyPath
        }
        else {
            let instance = StringKeyPath(string)
            KeyPathCache[string] = instance
            return instance
        }
    }

    private init(_ s: String) {
        rawValue = s
        count = rawValue.filter {
            $0 == "."
        }.count + 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.hashValue)
    }

    public var isPath: Bool {
        return 1 < count
    }

    public lazy var decompose : (head: StringKeyPath, tail: StringKeyPath?)? = {
        if 1 <= self.count {
            if let i = self.rawValue.firstIndex(of: ".") {
                let head = self.rawValue[..<i]
                var tail: StringKeyPath?
                if i != self.rawValue.endIndex {
                    let nextIndex = self.rawValue.index(after: i)
                    let result = self.rawValue[nextIndex...]
                    tail = StringKeyPath.keyPathForString(String(result))
                }
                return (StringKeyPath.keyPathForString(String(head)), tail)
            }
            return (self, nil)
        }
        return nil
    }()
}

extension StringKeyPath: Equatable {
}
public func == (lhs: StringKeyPath, rhs: StringKeyPath) -> Bool {
    // We store the hash which makes comparison very cheap.
    return (lhs.hashValue == rhs.hashValue) && (lhs.rawValue == rhs.rawValue)
}

extension StringKeyPath: CustomDebugStringConvertible {
    public var description: String {
        return rawValue
    }
    public var debugDescription: String {
        return rawValue
    }
}
