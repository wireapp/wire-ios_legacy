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

/// A circular array behaves like an array, but once it reaches a maximum size
/// new elements that are inserted will overwrite the oldest elements, allowing
/// for inserting an infinite amount of elements (at the cost of discarding the old ones)
public struct CircularArray<Element> {
    
    /// Max size
    private let size : Int
    
    /// A circular array used to store all lines
    /// Once it reaches the end (full), it starts to overwrite from the beginning
    /// The same operation could be achieved by appending to the end and removing from
    /// the front, but this would cause reallocating the array
    private var circularArray : [Element]
    
    /// Where to insert the next element
    private var listEnd = 0
    
    private var isFull : Bool {
        return self.circularArray.count == size
    }
    
    /// Insert an element in the array
    /// - Returns: old element that is going to be replaced with @c element
    @discardableResult public mutating func add(_ element: Element) -> Element? {
        let discardedElement: Element?
        
        if !self.isFull {
            circularArray.append(element)
            discardedElement = nil
        } else {
            discardedElement = circularArray[listEnd]
            circularArray[listEnd] = element
        }

        listEnd = (listEnd + 1) % size
        
        return discardedElement
    }
    
    /// Returns the cache content
    public var content : [Element] {
        if self.isFull {
            return Array(circularArray[listEnd..<size]) + Array(circularArray[0..<listEnd])
        }
        return Array(circularArray[0..<listEnd])
    }
    
    /// Remove content from cache
    public mutating func clear() {
        self.listEnd = 0
        self.circularArray = []
        self.circularArray.reserveCapacity(size)
    }
    
    public init(size: Int, initialValue: [Element] = []) {
        self.size = size
        self.circularArray = initialValue
        self.circularArray.reserveCapacity(size)
    }
}
