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

// MARK: - Standard URLS

extension URL {

    static var wr_usernameLearnMore: URL {
        return URL(string: "https://wire.com/support/username/")!
    }

    static var wr_fingerprintLearnMore: URL {
        return URL(string: "https://wire.com/privacy/why")!
    }

    static var wr_fingerprintHowToVerify: URL {
        return URL(string: "https://wire.com/privacy/how")!
    }

    static var wr_privacyPolicy: URL {
        return URL(string: "https://wire.com/legal/privacy/embed/")!
    }

    static var wr_licenseInformation: URL {
        return URL(string: "https://wire.com/legal/licenses/embed/")!
    }

    static var wr_website: URL {
        return URL(string: "https://wire.com")!
    }

    static var wr_passwordReset: URL {
        return URL(string: "https://account.wire.com/forgot/")!
    }

    static var wr_support: URL {
        return URL(string: "https://support.wire.com")!
    }

    static var wr_askSupport: URL {
        return URL(string: "https://support.wire.com/hc/requests/new")!
    }

    static var wr_reportAbuse: URL {
        return URL(string: "https://wire.com/support/misuse/")!
    }

    static var wr_cannotDecryptHelp: URL {
        return URL(string: "https://wire.com/privacy/error-1")!
    }

    static var wr_cannotDecryptNewRemoteIDHelp: URL {
        return URL(string: "https://wire.com/privacy/error-2")!
    }

    static var wr_createTeam: URL {
        return URL(string: "https://wire.com/create-team?pk_campaign=client&pk_kwd=ios")!
    }

    static var wr_createTeamFeatures: URL {
        return URL(string: "https://wire.com/teams/learnmore/")!
    }

    static var wr_manageTeam: URL {
        return URL(string: "https://teams.wire.com/login?pk_campaign=client&pk_kwd=ios")!
    }

    static var wr_emailInUseLearnMore: URL {
        return URL(string: "https://wire.com/support/email-in-use")!
    }

    static var wr_randomProfilePictureSource: URL {
        return URL(string: "https://source.unsplash.com/800x800/?landscape")!
    }

    static func wr_termsOfServicesURL(forTeamAccount isTeamAccount: Bool) -> URL {
        if isTeamAccount {
            return URL(string: "https://wire.com/legal/terms/teams")!
        } else {
            return URL(string: "https://wire.com/legal/terms/personal")!
        }
    }

}

extension NSURL {

    @objc class var wr_fingerprintLearnMoreURL: NSURL {
        return URL.wr_fingerprintLearnMore as NSURL
    }

    @objc class var wr_passwordResetURL: NSURL {
        return URL.wr_passwordReset as NSURL
    }

    @objc class var wr_websiteURL: NSURL {
        return URL.wr_website as NSURL
    }

}
