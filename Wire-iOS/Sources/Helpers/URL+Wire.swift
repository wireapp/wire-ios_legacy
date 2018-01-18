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

import UIKit

@objc enum TeamSource: Int {
    case onboarding, settings
    
    var parameterValue: String {
        switch self {
        case .onboarding: return "client_landing"
        case .settings: return "client_settings"
        }
    }
}

extension URL {
    
    var appendingLocaleParameter: URL {
        return (self as NSURL).wr_URLByAppendingLocaleParameter() as URL
    }
    
    static func manageTeam(source: TeamSource) -> URL {
        let query = "utm_source=\(source.parameterValue)&utm_term=ios"
        return URL(string: "https://teams.wire.com/login?\(query)")!.appendingLocaleParameter
    }
}

extension NSURL {
    @objc(manageTeamWithSource:) class func manageTeam(source: TeamSource) -> URL {
        return URL.manageTeam(source: source)
    }
}
