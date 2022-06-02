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

/**
 * An object containing the details required to create a team.
 */

public struct UnregisteredTeam: Equatable {

    public let teamName: String
    public let email: String
    public let emailCode: String
    public let fullName: String
    public let password: String
    public let accentColor: ZMAccentColor
    public let locale: String
    public let label: UUID?

    public init(teamName: String, email: String, emailCode: String, fullName: String, password: String, accentColor: ZMAccentColor) {
        self.teamName = teamName
        self.email = email
        self.emailCode = emailCode
        self.fullName = fullName
        self.password = password
        self.accentColor = accentColor
        self.locale = NSLocale.formattedLocaleIdentifier()!
        self.label = UIDevice.current.identifierForVendor
    }

    var payload: ZMTransportData {
        return [
            "email": email,
            "email_code": emailCode,
            "team": [
                "name": teamName,
                "icon": "abc"
            ],
            "accent_id": accentColor.rawValue,
            "locale": locale,
            "name": fullName,
            "password": password,
            "label": label?.uuidString ?? UUID().uuidString
            ] as ZMTransportData
    }
}
