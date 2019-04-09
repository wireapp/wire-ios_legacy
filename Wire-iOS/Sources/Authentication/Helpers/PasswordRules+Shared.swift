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

    var sortedRequirements: [PasswordCharacterClass] {
        return requiredCharacterSets.keys.sorted {
            switch $0 {
            case .lowercase: return true // lowercase always comes first
            case .uppercase: return $1 != .lowercase // uppercase always comes after lowercase
            case .digits: return $1 != .lowercase || $1 != .uppercase // digits always comes uppercase
            case .special: return true // Always put special characters at the end
            default: return true // Always put other cases at the end
            }
        }
    }

    /// The localized description for the rules.
    var localizedDescription: String {
        let minLengthRule = "registration.password.rules.min_length".localized(args: minimumLength)

        if sortedRequirements.isEmpty {
            return "registration.password.rules.no_requirements".localized(args: minLengthRule)
        }

        let ruleSegments = sortedRequirements.reduce(into: [minLengthRule]) { segments, requiredClass in
            switch requiredClass {
            case .digits:
                segments.append("registration.password.rules.number".localized(args: 1))
            case .lowercase:
                segments.append("registration.password.rules.lowercase".localized(args: 1))
            case .uppercase:
                segments.append("registration.password.rules.uppercase".localized(args: 1))
            case .special:
                segments.append("registration.password.rules.uppercase".localized(args: 1))
            default:
                return
            }
        }

        let formattedSegments = PasswordRuleSet.arrayFormatter.string(from: ruleSegments)!
        return "registration.password.rules.with_requirements".localized(args: minLengthRule, formattedSegments)
    }

}
