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

extension URLSessionConfiguration {
    
    @objc public var configurationDump: String {
        var dump = [
            "identifier: \(self.identifier ?? "nil")",
            "allowsCellularAccess: \(self.allowsCellularAccess)",
            "httpMaximumConnectionsPerHost: \(self.httpMaximumConnectionsPerHost)",
            "httpShouldUsePipelining: \(self.httpShouldUsePipelining)",
            "httpShouldSetCookies: \(self.httpShouldSetCookies)",
            "isDiscretionary: \(self.isDiscretionary)",
            "sessionSendsLaunchEvents: \(self.sessionSendsLaunchEvents)",
            "timeoutIntervalForRequest: \(self.timeoutIntervalForRequest)",
            "timeoutIntervalForResource: \(self.timeoutIntervalForResource)",
            "tlsMaximumSupportedProtocol: \(self.tlsMaximumSupportedProtocol)",
            "tlsMinimumSupportedProtocol: \(self.tlsMinimumSupportedProtocol)",
            "networkServiceType: \(self.networkServiceType.rawValue)"
        ]
        if #available(iOSApplicationExtension 9.0, *) {
            dump.append("shouldUseExtendedBackgroundIdleMode: \(self.shouldUseExtendedBackgroundIdleMode)")
        }
        return dump.joined(separator: "\n\t")
    }
}
