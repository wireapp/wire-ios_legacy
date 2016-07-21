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

public struct AnyClassTuple<T : Hashable> : Hashable {
    
    public let classOfObject : AnyClass
    public let secondElement : T
    public let hashValue : Int
    
    public init(classOfObject: AnyClass, secondElement: T) {
        self.classOfObject = classOfObject
        self.secondElement = secondElement
        self.hashValue = self.classOfObject.hash() ^ self.secondElement.hashValue
    }
}

public func ==<T>(lhs: AnyClassTuple<T>, rhs: AnyClassTuple<T>) -> Bool {
    // We store the hash which makes comparison very cheap.
    let secondAreEqual = (lhs.secondElement == rhs.secondElement)
    let classesAreEqual = (lhs.classOfObject === rhs.classOfObject)
    return (lhs.hashValue == rhs.hashValue)
        && secondAreEqual
        && classesAreEqual
}
