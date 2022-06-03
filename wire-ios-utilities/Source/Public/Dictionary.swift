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

extension Dictionary {
    
    /// Creates a dictionary by applying a function over a sequence, and assigning the calculated value to the sequence element. Also maps the keys
    public init<T, S: Sequence>(_ sequence: S, keyMapping: (T) -> Key, valueMapping: (T) -> Value) where S.Iterator.Element == T {
        
        self.init()
        
        for key in sequence {
            let newKey = keyMapping(key)
            let value = valueMapping(key)
            self[newKey] = value
        }
    }
    
    /// Maps a dictionary's keys and values to a new dictionary applying `keysMapping` to all keys and `valueMapping` 
    /// If `valueMapping` returns nil, the new dictionary will not contain the corresponding key
    public func mapKeysAndValues<NewKey, NewValue>(keysMapping: ((Key) -> NewKey),
                                                   valueMapping: ((Key, Value) -> NewValue?))
        -> Dictionary<NewKey, NewValue>
    {
        var dict = Dictionary<NewKey, NewValue>()
        for (key, value) in self {
            if let newValue = valueMapping(key, value) {
                dict.updateValue(newValue, forKey: keysMapping(key))
            }
        }
        return dict
    }
    
    /// Maps the key keeping the association with values
    public func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var mapping : [T : Value] = [:]
        for (key, value) in self {
            mapping[transform(key)] = value
        }
        return mapping
        
    }
    
    /// Creates a dictionary with the given keys and and sets `repeatedValue` as value for all keys
    public init(keys: [Key], repeatedValue: Value) {
        self.init()
        for key in keys {
            updateValue(repeatedValue, forKey: key)
        }
    }
    
    /// Joins two dictionaries with each other while overwriting existing values with values in `other`
    public func updated(other:Dictionary) -> Dictionary {
        var newDict = self
        for (key,value) in other {
            newDict.updateValue(value, forKey:key)
        }
        return newDict
    }
}




extension Sequence {
    
    /// Returns a dictionary created by key-value association as returned by the transform function.
    /// Multiple values with the same key will be overwritten by the last element of the sequence to return that key
    public func dictionary<K : Hashable, V>(_ transform: (Self.Iterator.Element) throws -> (key: K, value: V)) rethrows -> [K : V] {
        var mapping : [K : V] = [:]
        for value in self {
            let keyValue = try transform(value)
            mapping[keyValue.key] = keyValue.value
        }
        return mapping
    }
    
}
