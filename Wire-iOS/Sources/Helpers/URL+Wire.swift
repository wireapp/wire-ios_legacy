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
import WireSystem
import WireTransport

private let zmLog = ZMSLog(tag: "URL")

enum TeamSource: Int {
    case onboarding, settings

    var parameterValue: String {
        switch self {
        case .onboarding: return "client_landing"
        case .settings: return "client_settings"
        }
    }
}

struct WireUrl: Codable {
    let wireAppOnItunes: URL
    let support: URL
    let randomProfilePictureSource: URL

    static var shared: WireUrl! = {
        return WireUrl(filePath: Bundle.fileURL(for: "url", with: "json")!)
    }()

    private init?(filePath: URL) {
        do {
            self = try filePath.decode(WireUrl.self)
        } catch {
            return nil
        }
    }
}

extension URL {

    var appendingLocaleParameter: URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let localeQueryItem = URLQueryItem(name: "hl", value: Locale.current.identifier)

        var queryItems = components.queryItems ?? []
        queryItems.append(localeQueryItem)
        components.queryItems = queryItems

        return components.url ?? self
    }

    static func manageTeam(source: TeamSource) -> URL {
        let baseURL = BackendEnvironment.shared.teamsURL

        let queryItems = [URLQueryItem(name: "utm_source", value: source.parameterValue),
                          URLQueryItem(name: "utm_term", value: "ios")]

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        components?.queryItems = queryItems

        return components!.url!.appendingLocaleParameter
    }
}

// MARK: - Standard URLS

extension BackendEnvironment {
    fileprivate static func websiteLink(path: String) -> URL {
        return shared.websiteURL.appendingPathComponent(path)
    }

    fileprivate static func accountsLink(path: String) -> URL {
        return shared.accountsURL.appendingPathComponent(path)
    }

    fileprivate static func teamsLink(path: String) -> URL {
        return shared.teamsURL.appendingPathComponent(path)
    }

}

extension URL {

    static var wr_wireAppOnItunes: URL {
        return WireUrl.shared.wireAppOnItunes
    }

    static var wr_randomProfilePictureSource: URL {
        return WireUrl.shared.randomProfilePictureSource
    }

    static var wr_emailAlreadyInUseLearnMore: URL {
        return wr_support.appendingPathComponent("hc/en-us/articles/115004082129-My-email-address-is-already-in-use-and-I-cannot-create-an-account-What-can-I-do-")
    }

    static var wr_support: URL {
        return WireUrl.shared.support
    }

    static var wr_usernameLearnMore: URL {
        return BackendEnvironment.websiteLink(path: "support/username")
    }

    static var wr_fingerprintLearnMore: URL {
        return BackendEnvironment.websiteLink(path: "privacy/why")
    }

    static var wr_fingerprintHowToVerify: URL {
        return BackendEnvironment.websiteLink(path: "privacy/how")
    }

    static var wr_privacyPolicy: URL {
        return BackendEnvironment.websiteLink(path: "legal/privacy/embed")
    }

    static var wr_licenseInformation: URL {
        return BackendEnvironment.websiteLink(path: "legal/licenses/embed")
    }

    static var wr_website: URL {
        return BackendEnvironment.shared.websiteURL
    }

    static var wr_passwordReset: URL {
        return BackendEnvironment.accountsLink(path: "forgot")
    }

    static var wr_askSupport: URL {
        return wr_support.appendingPathComponent("hc/requests/new")
    }

    static var wr_reportAbuse: URL {
        return BackendEnvironment.websiteLink(path: "support/misuse")
    }

    static var wr_cannotDecryptHelp: URL {
        return BackendEnvironment.websiteLink(path: "privacy/error-1")
    }

    static var wr_cannotDecryptNewRemoteIDHelp: URL {
        return BackendEnvironment.websiteLink(path: "privacy/error-2")
    }

    static var wr_createTeamFeatures: URL {
        return BackendEnvironment.websiteLink(path: "teams/learnmore")
    }

    static var wr_emailInUseLearnMore: URL {
        return BackendEnvironment.websiteLink(path: "support/email-in-use")
    }

    static var wr_searchSupport: URL {
        return BackendEnvironment.websiteLink(path: "support/search") // TODO jacob update URL when support page exists
    }

    static func wr_termsOfServicesURL(forTeamAccount isTeamAccount: Bool) -> URL {
        if isTeamAccount {
            return BackendEnvironment.websiteLink(path: "legal/terms/teams")
        } else {
            return BackendEnvironment.websiteLink(path: "legal/terms/personal")
        }
    }

    static var wr_legalHoldLearnMore: URL {
        return wr_support.appendingPathComponent("hc/articles/360002018278-What-is-legal-hold-")
    }

}

extension NSURL {

    static var wr_fingerprintLearnMoreURL: NSURL {
        return URL.wr_fingerprintLearnMore as NSURL
    }

}
