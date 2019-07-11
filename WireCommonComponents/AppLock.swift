//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel
import LocalAuthentication

public class AppLock {
    // Returns true if user enabled the app lock feature.
    public static var isActive: Bool {
        get {
            guard !AppLockRules.shared.forceAppLock else { return true }
            guard let data = ZMKeychain.data(forAccount: SettingsPropertyName.lockApp.rawValue),
                data.count != 0 else {
                    return false
            }
            
            return String(data: data, encoding: .utf8) == "YES"
        }
        set {
            guard !AppLockRules.shared.forceAppLock else { return }
            let data = (newValue ? "YES" : "NO").data(using: .utf8)!
            ZMKeychain.setData(data, forAccount: SettingsPropertyName.lockApp.rawValue)
        }
    }
    
    // Returns the time since last lock happened as number of seconds since the reference date.
    public static var lastUnlockDateAsInt: UInt32 {
        get {
            guard let data = ZMKeychain.data(forAccount: SettingsPropertyName.lockAppLastDate.rawValue),
                data.count != 0 else {
                    return 0
            }
            
            let intBits = data.withUnsafeBytes({(bytePointer: UnsafeRawBufferPointer) -> UInt32 in
                bytePointer.bindMemory(to: UInt8.self).baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 4) { pointer in
                    return pointer.pointee
                }
            })
            
            return UInt32(littleEndian: intBits)
        }
        set {
            var value: UInt32 = newValue
            let data = withUnsafePointer(to: &value) {
                Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: newValue))
            }
            
            ZMKeychain.setData(data, forAccount: SettingsPropertyName.lockAppLastDate.rawValue)
        }
    }
    
    // Returns the time since last lock happened.
    public static var lastUnlockedDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: TimeInterval(self.lastUnlockDateAsInt))
        }
        
        set {
            self.lastUnlockDateAsInt = UInt32(newValue.timeIntervalSinceReferenceDate)
        }
    }
    
    // Creates a new LAContext and evaluates the authentication settings of the user.
    public static func evaluateAuthentication(description: String, with callback: @escaping (Bool?, Error?)->()) {
    
        let context: LAContext = LAContext()
        var error: NSError?
    
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication,
                                   localizedReason: description,
                                   reply: { (success, error) -> Void in
                callback(success, error)
            })
        } else {
            callback(.none, error)
        }
    }
    
}


public struct AppLockRules: Decodable {
    
    public let forceAppLock: Bool
    public let timeout: UInt
    
    /// The shared rule set.
    public static var shared: AppLockRules = {
        let fileURL = Bundle.main.url(forResource: "applock", withExtension: "json")!
        let fileData = try! Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try! decoder.decode(AppLockRules.self, from: fileData)
    }()
}
