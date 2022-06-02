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

public class MockEnvironment: NSObject, BackendEnvironmentProvider {

    var isServerTrusted = true
    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        return isServerTrusted
    }
    public var title: String = "Example"
    public var backendURL: URL = URL(string: "http://example.com")!
    public var backendWSURL: URL = URL(string: "http://example.com")!
    public var blackListURL: URL = URL(string: "https://clientblacklist.wire.com/prod/ios")!
    public var teamsURL: URL = URL(string: "http://example.com")!
    public var accountsURL: URL = URL(string: "http://example.com")!
    public var websiteURL: URL = URL(string: "http://example.com")!
    public var countlyURL: URL? = URL(string: "http://example.com")!
    public var environmentType: EnvironmentTypeProvider = EnvironmentTypeProvider(environmentType: .production)
}
