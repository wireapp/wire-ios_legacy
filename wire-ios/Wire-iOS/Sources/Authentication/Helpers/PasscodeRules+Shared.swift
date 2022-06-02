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
import WireUtilities
import FormatterKit

extension PasswordRuleSet {

    private static let arrayFormatter = TTTArrayFormatter()

    /// The shared rule set.
    static let shared: PasswordRuleSet = {
        let fileURL = Bundle.main.url(forResource: "password_rules", withExtension: "json")!
        let fileData = try! Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try! decoder.decode(PasswordRuleSet.self, from: fileData)
    }()

    // MARK: - Localized Description

    /// The localized error message for the shared rule set.
    static let localizedErrorMessage: String = {
        let ruleSet = PasswordRuleSet.shared
        let minLengthRule = "registration.password.rules.min_length".localized(args: ruleSet.minimumLength)

        if ruleSet.requiredCharacters.isEmpty {
            return "registration.password.rules.no_requirements".localized(args: minLengthRule)
        }

        let localizedRules: [String] = ruleSet.requiredCharacters.compactMap { requiredClass in
            switch requiredClass {
            case .digits:
                return "registration.password.rules.number".localized(args: 1)
            case .lowercase:
                return "registration.password.rules.lowercase".localized(args: 1)
            case .uppercase:
                return "registration.password.rules.uppercase".localized(args: 1)
            case .special:
                return "registration.password.rules.special".localized(args: 1)
            default:
                return nil
            }
        }

        let formattedRulesList = PasswordRuleSet.arrayFormatter.string(from: localizedRules)!
        return "registration.password.rules.with_requirements".localized(args: minLengthRule, formattedRulesList)
    }()

}
