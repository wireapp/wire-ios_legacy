//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// In memory cache with support for generics.

public class Cache<Key: Hashable, Value> {
    private var cache: [Key: EntryMetadata<Value>] = [:]
    private var cacheBuffer: CircularArray<Key>
    private let maxCost: Int
    private let maxElementsCount: Int
    private var currentCost: Int = 0
    
    private struct EntryMetadata<Value> {
        let value: Value
        let cost: Int
        
        init(value: Value, cost: Int) {
            self.value = value
            self.cost = cost
        }
    }
    
    /// Create a new cache
    ///
    /// When any of the limits are reached the oldest value in the Cache will be removed first.
    ///
    /// - Parameters:
    ///     - maxCost: Maximum cost which can be stored in cached before entries are purged.
    ///     - maxElementsCount: Maximum number of elements which can be stored in the cached before entries are
    ///       purged.
    public init(maxCost: Int, maxElementsCount: Int) {
        assert(maxCost > 0, "maxCost must be greather than 0")
        assert(maxElementsCount > 0, "maxElementsCount must be greather than 0")
        self.maxCost = maxCost
        self.maxElementsCount = maxElementsCount
        cacheBuffer = CircularArray<Key>(size: maxElementsCount)
    }
    
    /// Add a value to the cache
    ///
    /// - Parameters:
    ///     - value: Value which should be stored in the cache.
    ///     - key: Key by which the value later can be retrieved.
    ///     - cost: How much it costs to store value. This will be used to determine if values need purged
    ///             from the cache when the cost limit has been reached.
    /// - Returns: Boolean set to true if values had to be purged in order to make room for the new value,
    ///            otherwise false.
    @discardableResult
    public func set(value: Value, for key: Key, cost: Int) -> Bool {
        assert(cost > 0, "Cost must be greather than 0")
        cache[key] = EntryMetadata(value: value, cost: cost)
        currentCost = currentCost + cost
        
        var didPurgeItems = false
        didPurgeItems = didPurgeItems || purgeBasedOnElementsCount(adding: key)
        didPurgeItems = didPurgeItems || purgeBasedOnCost()
        
        return didPurgeItems
    }
    
    /// Retrieve a value from the cache
    ///
    /// - Parameters:
    ///     - key: Key used to retrieve a previously stored value.
    /// - Returns: Value if it exists the cache.
    public func value(for key: Key) -> Value? {
        return cache[key]?.value
    }
    
    /// Remove all values from the cache.
    public func purge() {
        cache.removeAll()
        cacheBuffer.clear()
        currentCost = 0
    }

    private func purgeBasedOnElementsCount(adding key: Key) -> Bool {
        guard let discardedElement = cacheBuffer.add(key) else {
            return false
        }
        let metadata = cache[discardedElement]!
        currentCost = currentCost - metadata.cost

        cache[discardedElement] = nil
        
        return true
    }
    
    private func purgeBasedOnCost() -> Bool {
        guard currentCost > maxCost else {
            return false
        }
        
        var elementsToDiscard: Int = 0

        // Get the objects from the current cache buffer
        let currentCacheBuffer = cacheBuffer.content
        
        for key in currentCacheBuffer {
            // Find the corresponding element's metadata
            let metadata = cache[key]!
            
            // Advance one index forward
            elementsToDiscard = elementsToDiscard + 1

            // Erase cached object from the cache
            cache[key] = nil
            currentCost = currentCost - metadata.cost
            
            // check if the cost is back to normal
            if currentCost <= maxCost {
                break
            }
        }

        // rebuild cacheBuffer, since as many as `elementsToDiscard` number of elements must be discarded
        let numberOfElementsToKeep = currentCacheBuffer.count - elementsToDiscard
        let elementsToKeep = currentCacheBuffer.suffix(numberOfElementsToKeep)

        cacheBuffer = CircularArray(size: maxElementsCount, initialValue: Array(elementsToKeep))
        
        return true
    }
    
}
