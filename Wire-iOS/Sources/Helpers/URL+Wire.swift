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

import Foundation

private let zmLog = ZMSLog(tag: "URL")

@objc enum TeamSource: Int {
    case onboarding, settings
    
    var parameterValue: String {
        switch self {
        case .onboarding: return "client_landing"
        case .settings: return "client_settings"
        }
    }
}

struct WireUrl: Codable {
    static var shared: WireUrl! = {
        guard let filePath = Bundle.main.url(forResource: "url", withExtension: "json") else { return nil }

        return WireUrl(filePath: filePath)
    }()

    private init?(filePath: URL) {

        let data: Data
        do {
            data = try Data(contentsOf: filePath)
        } catch {
            zmLog.error("Failed to load URL at path: \(filePath), error: \(error)")
            return nil
        }

        let decoder = JSONDecoder()

        let dictionary: [String: String]
        do {
            dictionary = try decoder.decode([String: String].self, from: data)
        } catch {
            zmLog.error("Failed to parse JSON at path: \(filePath), error: \(error)")
            return nil
        }

        urls = Dictionary(uniqueKeysWithValues: dictionary.map { key, value in (key, URL(string: value)!) })
    }

    let urls: [String : URL]
}

extension URL {

    var appendingLocaleParameter: URL {
        return (self as NSURL).wr_URLByAppendingLocaleParameter() as URL
    }

    static func manageTeam(source: TeamSource) -> URL {
        let baseURL = WireUrl.shared.urls["manageTeamBase"]!

        let queryItems = [URLQueryItem(name: "utm_source", value: source.parameterValue),
                          URLQueryItem(name: "utm_term", value: "ios")]

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        components?.queryItems = queryItems

        return components!.url!.appendingLocaleParameter
    }
}

// MARK: - Standard URLS

extension URL {

    static var wr_wireAppOnItunes: URL {
        return WireUrl.shared.urls["wireAppOnItunes"]!
    }

    static var wr_emailAlreadyInUseLearnMore: URL {
        return WireUrl.shared.urls["emailAlreadyInUseLearnMore"]!
    }

    static var wr_usernameLearnMore: URL {
        return WireUrl.shared.urls["usernameLearnMore"]!
    }

    static var wr_fingerprintLearnMore: URL {
        return WireUrl.shared.urls["fingerprintLearnMore"]!
    }

    static var wr_fingerprintHowToVerify: URL {
        return WireUrl.shared.urls["fingerprintHowToVerify"]!
    }

    static var wr_privacyPolicy: URL {
        return WireUrl.shared.urls["privacyPolicy"]!
    }

    static var wr_licenseInformation: URL {
        return WireUrl.shared.urls["licenseInformation"]!
    }

    static var wr_website: URL {
        return WireUrl.shared.urls["website"]!
    }

    static var wr_passwordReset: URL {
        return WireUrl.shared.urls["passwordReset"]!
    }

    static var wr_support: URL {
        return WireUrl.shared.urls["support"]!
    }

    static var wr_askSupport: URL {
        return WireUrl.shared.urls["askSupport"]!
    }

    static var wr_reportAbuse: URL {
        return WireUrl.shared.urls["reportAbuse"]!
    }

    static var wr_cannotDecryptHelp: URL {
        return WireUrl.shared.urls["cannotDecryptHelp"]!
    }

    static var wr_cannotDecryptNewRemoteIDHelp: URL {
        return WireUrl.shared.urls["cannotDecryptNewRemoteIDHelp"]!
    }

    static var wr_createTeam: URL {
        return WireUrl.shared.urls["createTeam"]!
    }

    static var wr_createTeamFeatures: URL {
        return WireUrl.shared.urls["createTeamFeatures"]!
    }

    static var wr_manageTeam: URL {
        return WireUrl.shared.urls["manageTeam"]!
    }

    static var wr_emailInUseLearnMore: URL {
        return WireUrl.shared.urls["emailInUseLearnMore"]!
    }

    static var wr_randomProfilePictureSource: URL {
        return WireUrl.shared.urls["randomProfilePictureSource"]!
    }

    static func wr_termsOfServicesURL(forTeamAccount isTeamAccount: Bool) -> URL {
        if isTeamAccount {
            return WireUrl.shared.urls["termsOfServicesURL_teams"]!
        } else {
            return WireUrl.shared.urls["termsOfServicesURL_personal"]!
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
