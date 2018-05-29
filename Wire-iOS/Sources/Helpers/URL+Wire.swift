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

// MARK: - Standard URLS

extension URL {

    static var wr_fingerprintLearnMoreURL: URL {
        return NSURL.__wr_fingerprintLearnMore() as URL
    }

    static var wr_fingerprintHowToVerify: URL {
        return NSURL.__wr_fingerprintHowToVerify() as URL
    }

    static var wr_privacyPolicy: URL {
        return NSURL.__wr_privacyPolicy() as URL
    }

    static var wr_licenseInformation: URL {
        return NSURL.__wr_licenseInformation() as URL
    }

    static var wr_website: URL {
        return NSURL.__wr_website() as URL
    }

    static var wr_passwordReset: URL {
        return NSURL.__wr_passwordReset() as URL
    }

    static var wr_support: URL {
        return NSURL.__wr_support() as URL
    }

    static var wr_askSupport: URL {
        return NSURL.__wr_askSupport() as URL
    }

    static var wr_reportAbuse: URL {
        return NSURL.__wr_reportAbuse() as URL
    }

    static var wr_cannotDecryptHelp: URL {
        return NSURL.__wr_cannotDecryptHelp() as URL
    }

    static var wr_cannotDecryptNewRemoteIDHelp: URL {
        return NSURL.__wr_cannotDecryptNewRemoteIDHelp() as URL
    }

    static var wr_createTeam: URL {
        return NSURL.__wr_createTeam() as URL
    }

    static var wr_createTeamFeatures: URL {
        return NSURL.__wr_createTeamFeatures() as URL
    }

    static var wr_manageTeam: URL {
        return NSURL.__wr_manageTeam() as URL
    }

    static var wr_emailInUseLearnMore: URL {
        return NSURL.__wr_emailInUseLearnMore() as URL
    }

    static func wr_termsOfServicesURL(forTeamAccount: Bool) -> URL {
        return NSURL.__wr_termsOfServicesURL(forTeamAccount: forTeamAccount) as URL
    }

}
