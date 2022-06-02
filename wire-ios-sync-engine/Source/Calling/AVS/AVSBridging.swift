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
 * A protocol for values that can be decoded from a C counterpart from AVS.
 */

protocol AVSValue {

    /// The type of the value in AVS APIs.
    associatedtype AVSType

    /**
     * Attemps to convert the value from the AVS type to Swift.
     * - parameter rawValue: The value to decode from AVS.
     * - returns: The Swift-converted object, if the `rawValue` was valid.
     */

    init?(rawValue: AVSType)

}

/**
 * An enum that can be represented as AVS flags.
 */

protocol AVSEnum: RawRepresentable, AVSValue {}

// MARK: - AVS Types

extension AVSConversationType: AVSEnum {
    typealias AVSType = RawValue
}

extension VideoState: AVSEnum {
    typealias AVSType = RawValue
}

extension CallClosedReason: AVSValue {
    public init?(rawValue: Int32) {
        self.init(wcall_reason: rawValue)
    }
}

extension NetworkQuality: AVSEnum {
    typealias AVSType = RawValue
}

extension Bool: AVSValue {
    init(rawValue: Int32) {
        self = rawValue == 1
    }
}

extension Date: AVSValue {
    init(rawValue: UInt32) {
        self = Date(timeIntervalSince1970: TimeInterval(rawValue))
    }
}

extension UUID: AVSValue {

    init?(rawValue: UnsafePointer<Int8>?) {
        self.init(cString: rawValue)
    }

    /// Creates the UUID from a C string pointer, if it is valid.
    init?(cString: UnsafePointer<Int8>?) {
        guard let aString = String(cString: cString) else { return nil }
        self.init(uuidString: aString)
    }

}

extension String: AVSValue {

    init?(rawValue: UnsafePointer<Int8>) {
        self.init(cString: rawValue)
    }

    /// Creates the String from a C string pointer, if it is valid.
    init?(cString: UnsafePointer<Int8>?) {
        if let cString = cString {
            self.init(cString: cString)
        } else {
            return nil
        }
    }

}

// MARK: - Decoding

extension AVSWrapper {

    @discardableResult
    static func withCallCenter(_ contextRef: UnsafeMutableRawPointer?, _ block: (WireCallCenterV3) -> Void) -> Int32 {
        guard let contextRef = contextRef else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ block: (WireCallCenterV3, A1) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue, A2: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ v2: A2.AVSType?, _ block: (WireCallCenterV3, A1, A2) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init), let value2 = v2.flatMap(A2.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1, value2)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue, A2: AVSValue, A3: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ v2: A2.AVSType?, _ v3: A3.AVSType?, _ block: (WireCallCenterV3, A1, A2, A3) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init), let value2 = v2.flatMap(A2.init), let value3 = v3.flatMap(A3.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1, value2, value3)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue, A2: AVSValue, A3: AVSValue, A4: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ v2: A2.AVSType?, _ v3: A3.AVSType?, _ v4: A4.AVSType?, _ block: (WireCallCenterV3, A1, A2, A3, A4) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init), let value2 = v2.flatMap(A2.init), let value3 = v3.flatMap(A3.init), let value4 = v4.flatMap(A4.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1, value2, value3, value4)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue, A2: AVSValue, A3: AVSValue, A4: AVSValue, A5: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ v2: A2.AVSType?, _ v3: A3.AVSType?, _ v4: A4.AVSType?, _ v5: A5.AVSType?, _ block: (WireCallCenterV3, A1, A2, A3, A4, A5) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init), let value2 = v2.flatMap(A2.init), let value3 = v3.flatMap(A3.init), let value4 = v4.flatMap(A4.init), let value5 = v5.flatMap(A5.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1, value2, value3, value4, value5)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue, A2: AVSValue, A3: AVSValue, A4: AVSValue, A5: AVSValue, A6: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ v2: A2.AVSType?, _ v3: A3.AVSType?, _ v4: A4.AVSType?, _ v5: A5.AVSType?, _ v6: A6.AVSType?, _ block: (WireCallCenterV3, A1, A2, A3, A4, A5, A6) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init), let value2 = v2.flatMap(A2.init), let value3 = v3.flatMap(A3.init), let value4 = v4.flatMap(A4.init), let value5 = v5.flatMap(A5.init), let value6 = v6.flatMap(A6.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1, value2, value3, value4, value5, value6)
        return 0
    }

    @discardableResult
    static func withCallCenter<A1: AVSValue, A2: AVSValue, A3: AVSValue, A4: AVSValue, A5: AVSValue, A6: AVSValue, A7: AVSValue>(_ contextRef: UnsafeMutableRawPointer?, _ v1: A1.AVSType?, _ v2: A2.AVSType?, _ v3: A3.AVSType?, _ v4: A4.AVSType?, _ v5: A5.AVSType?, _ v6: A6.AVSType?, _ v7: A7.AVSType?, _ block: (WireCallCenterV3, A1, A2, A3, A4, A5, A6, A7) -> Void) -> Int32 {
        guard let contextRef = contextRef, let value1 = v1.flatMap(A1.init), let value2 = v2.flatMap(A2.init), let value3 = v3.flatMap(A3.init), let value4 = v4.flatMap(A4.init), let value5 = v5.flatMap(A5.init), let value6 = v6.flatMap(A6.init), let value7 = v7.flatMap(A7.init) else { return EINVAL }
        let callCenter = Unmanaged<WireCallCenterV3>.fromOpaque(contextRef).takeUnretainedValue()
        block(callCenter, value1, value2, value3, value4, value5, value6, value7)
        return 0
    }

}
