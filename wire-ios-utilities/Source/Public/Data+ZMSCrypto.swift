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

// Mapping of @c NSData helper methods to Swift 3 @c Data. See original methods for description.
public extension Data {
    
    init?(hexString: String) {
        guard let decodedData = hexString.zmHexDecodedData() else {
            return nil
        }
        self = decodedData
    }
    
    func zmMD5Digest() -> Data {
        return (self as NSData).zmMD5Digest()
    }
    
    func zmHMACSHA256Digest(key: Data) -> Data {
        return (self as NSData).zmHMACSHA256Digest(withKey: key)
    }
    
    func zmHexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var characters : [unichar] = []
        characters.reserveCapacity(count * 2)
        
        self.forEach { byte in
            characters.append(hexDigits[Int(byte / 16)])
            characters.append(hexDigits[Int(byte % 16)])
        }
        
        return String(utf16CodeUnits: characters, count: characters.count)
    }
        
    static func zmRandomSHA256Key() -> Data {
        return NSData.zmRandomSHA256Key()
    }
    
    func zmSHA256Digest() -> Data {
        return (self as NSData).zmSHA256Digest()
    }
    
    func base64String() -> String {
        return (self as NSData).base64String()
    }
    
    func zmEncryptPrefixingIV(key: Data) -> Data {
        return (self as NSData).zmEncryptPrefixingIV(withKey: key)
    }
    
    func zmDecryptPrefixedIV(key: Data) -> Data {
        return (self as NSData).zmDecryptPrefixedIV(withKey: key)
    }
    
    func zmEncryptPrefixingPlainTextIV(key: Data) -> Data {
        return (self as NSData).zmEncryptPrefixingPlainTextIV(withKey: key)
    }
    
    func zmDecryptPrefixedPlainTextIV(key: Data) -> Data? {
        return (self as NSData).zmDecryptPrefixedPlainTextIV(withKey: key)
    }
    
    static func secureRandomData(length: UInt) -> Data {
        return NSData.secureRandomData(ofLength: length)
    }
    
    static func randomEncryptionKey() -> Data {
        return NSData.randomEncryptionKey()
    }
    
}
