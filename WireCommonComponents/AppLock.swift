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

public struct AppLockRules: Codable {
    public let useBiometricsOrAccountPassword: Bool
    public let useCustomCodeInsteadOfAccountPassword: Bool
    public let forceAppLock: Bool
    public let appLockTimeout: UInt
    public let isEnabled: Bool
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        useBiometricsOrAccountPassword = try container.decode(Bool.self, forKey: .useBiometricsOrAccountPassword)
        useCustomCodeInsteadOfAccountPassword = try container.decode(Bool.self, forKey: .useCustomCodeInsteadOfAccountPassword)
        forceAppLock = try container.decode(Bool.self, forKey: .forceAppLock)
        appLockTimeout = try container.decode(UInt.self, forKey: .appLockTimeout)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
    
    public static func fromBundle() -> AppLockRules {
        if let fileURL = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let fileData = try? Data(contentsOf: fileURL) {
            return fromData(fileData)
        } else {
            fatalError("session_manager.json not exist")
        }
    }
    
    public static func fromData(_ data: Data) -> AppLockRules {
        let decoder = JSONDecoder()
        return try! decoder.decode(AppLockRules.self, from: data)
    }
}

// MARK: - For testing purposes
extension AppLockRules {
    init(useBiometricsOrAccountPassword: Bool,
         useCustomCodeInsteadOfAccountPassword: Bool,
         forceAppLock: Bool,
         appLockTimeout: UInt) {
        self.useBiometricsOrAccountPassword = useBiometricsOrAccountPassword
        self.useCustomCodeInsteadOfAccountPassword = useCustomCodeInsteadOfAccountPassword
        self.forceAppLock = forceAppLock
        self.appLockTimeout = appLockTimeout
        self.isEnabled = true
    }
}
