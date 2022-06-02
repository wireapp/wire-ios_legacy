//
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

// TODO-SWIFT: convert to struct
@objc(ZMAccessToken) @objcMembers
public class AccessToken: NSObject {
    
    public let token: String
    public let type: String
    public let expirationDate: Date
    
    @objc(initWithToken:type:expiresInSeconds:)
    public init(token: String, type: String, expiresInSeconds: UInt) {
        self.token = token
        self.type = type
        self.expirationDate = Date(timeIntervalSinceNow: Double(expiresInSeconds))
    }
    
    @objc
    public var httpHeaders: [String: String] {
        return ["Authorization" : "\(self.type) \(self.token)"]
    }
}
