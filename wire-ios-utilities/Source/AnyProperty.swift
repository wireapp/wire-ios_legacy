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

/**
 * A wrapper that can be used to access a property inside a type-erased box.
 *
 * You typically create this wrapper by passing the object of the type you want
 * to erase, and the key path to the property you want to access inside the box.
 *
 * When you want to access the value, call the `getter()` block.
 */

public struct AnyConstantProperty<Value> {

    /// The block that returns the value from the erased object.
    public let getter: () -> Value

    /**
     * Creates the type-erased accessor for a property inside another object.
     * - parameter base: The object that contains the property.
     * - parameter keyPath: The key path to the value.
     * - note: The `base` object will be retained by the box.
     */

    public init<Base>(_ base: Base, keyPath: Swift.KeyPath<Base, Value>) {
        getter = {
            return base[keyPath: keyPath]
        }
    }
}

/**
 * A wrapper that can be used to get and set a property inside a type-erased box.
 *
 * You typically create this wrapper by passing the object of the type you want
 * to erase, and the key path to the property you want to access inside the box.
 *
 * When you want to get the value, call the `getter()` block. When you want to change
 * the value in the type-erased value, call the `setter()` block with the new value.
 */

public struct AnyMutableProperty<Value> {
    /// The block that returns the value from the erased object.
    public let getter: () -> Value

    /// The block that changes the value inside the erased object.
    public let setter: (Value) -> Void

    /**
     * Creates the type-erased accessor for a mutable property inside another object.
     * - parameter base: The object that contains the property.
     * - parameter keyPath: The key path to the value.
     * - note: The `base` object will be retained by the box.
     */

    public init<Base>(_ base: Base, keyPath: ReferenceWritableKeyPath<Base, Value>) {
        getter = {
            return base[keyPath: keyPath]
        }

        setter = { newValue in
            base[keyPath: keyPath] = newValue
        }
    }
}
