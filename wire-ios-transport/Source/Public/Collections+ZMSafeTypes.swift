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
import WireSystem

private let zmLog = ZMSLog(tag: "SafeTypes")


func lastCallstackFrames() -> String {
    let symbols = Thread.callStackSymbols
    return symbols[min(3,symbols.count)..<(min(15, symbols.count))].joined(separator: "\n")
}


func objectWhichIsKindOfClass<T>(dictionary: NSDictionary, key: String, required: Bool, transform: ((String) -> T?)?) -> T? {
    if let object = dictionary[key] as? T {
        return object
    }
    if let transform = transform {
        if let string = dictionary[key] as? String, let object = transform(string) {
            return object
        }
    }
    if let object = dictionary[key], !(object is NSNull) {
        zmLog.error("\(object) is not a valid \(T.self) in \(dictionary). Callstack:\n \(lastCallstackFrames())")
    } else if (required) {
        zmLog.error("nil values for \(key) in \(dictionary). Callstack:\n \(lastCallstackFrames())")
    }
    return nil
}

func requiredObjectWhichIsKindOfClass<T>(dictionary: NSDictionary, key: String, transform: ((String) -> T?)? = nil) -> T? {
    return objectWhichIsKindOfClass(dictionary: dictionary, key: key, required: true, transform: transform)
}

func optionalObjectWhichIsKindOfClass<T>(dictionary: NSDictionary, key: String, transform: ((String) -> T?)? = nil) -> T? {
    return objectWhichIsKindOfClass(dictionary: dictionary, key: key, required: false, transform: transform)
}

extension NSDictionary {

    @objc public func string(forKey key: String) -> String? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func optionalString(forKey key: String) -> String? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func number(forKey key: String) -> NSNumber? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func optionalNumber(forKey key: String) -> NSNumber? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    @objc public func array(forKey key: String) -> [AnyObject]? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func optionalArray(forKey key: String) -> [AnyObject]? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    @objc public func data(forKey key: String) -> Data? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func optionalData(forKey key: String) -> Data? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func dictionary(forKey key: String) -> [String: AnyObject]? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func optionalDictionary(forKey key: String) -> [String: AnyObject]? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key)
    }
    
    @objc public func uuid(forKey key: String) -> UUID? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key){UUID(uuidString:$0)}
    }
    
    @objc public func optionalUuid(forKey key: String) -> UUID? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key){UUID(uuidString:$0)}
    }
    
    @objc
    public func date(for key: String) -> Date? {
        return requiredObjectWhichIsKindOfClass(dictionary: self, key: key) { NSDate(transport: $0) as Date? }
    }

    @objc public func optionalDate(forKey key: String) -> Date? {
        return optionalObjectWhichIsKindOfClass(dictionary: self, key: key) { NSDate(transport: $0) as Date? }
    }
}


