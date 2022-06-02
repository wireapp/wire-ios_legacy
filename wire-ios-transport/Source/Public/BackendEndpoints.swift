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

final class BackendEndpoints: NSObject, BackendEndpointsProvider, Codable {
    let backendURL: URL
    let backendWSURL: URL
    let blackListURL: URL
    let teamsURL: URL
    let accountsURL: URL
    let websiteURL: URL
    let countlyURL: URL?

    init(backendURL: URL,
         backendWSURL: URL,
         blackListURL: URL,
         teamsURL: URL,
         accountsURL: URL,
         websiteURL: URL,
         countlyURL: URL?) {
        self.backendURL = backendURL
        self.backendWSURL = backendWSURL
        self.blackListURL = blackListURL
        self.teamsURL = teamsURL
        self.accountsURL = accountsURL
        self.websiteURL = websiteURL
        self.countlyURL = countlyURL
        
        super.init()
    }
}
