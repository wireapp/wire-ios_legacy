
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

public struct CustomAppLockRules: Decodable { ///TODO: merge with AppLockRules?
    public let forceCustomAppLock: Bool
    
    public static func fromBundle() -> CustomAppLockRules {
        if let fileURL = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let fileData = try? Data(contentsOf: fileURL) {
            return fromData(fileData)
        } else {
            fatalError("session_manager.json not exist")
        }
    }
    
    public static func fromData(_ data: Data) -> CustomAppLockRules {
        let decoder = JSONDecoder()
        return try! decoder.decode(CustomAppLockRules.self, from: data)
    }
}

public class CustomAppLock { ///TODO: merge with AppLock?
    public static var rules = CustomAppLockRules.fromBundle()

    public static var isActive: Bool {
        get {
            guard !rules.forceCustomAppLock else { return true }
            guard let data = ZMKeychain.data(forAccount: SettingsPropertyName.customAppLock.rawValue),
                data.count != 0 else {
                    return false
            }
            
            return String(data: data, encoding: .utf8) == "YES"
        }
        set {
            guard !rules.forceCustomAppLock else { return }
            let data = (newValue ? "YES" : "NO").data(using: .utf8)!
            ZMKeychain.setData(data, forAccount: SettingsPropertyName.customAppLock.rawValue)
        }
    }
}
