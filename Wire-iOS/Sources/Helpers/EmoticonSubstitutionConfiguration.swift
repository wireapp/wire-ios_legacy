// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import WireSystem

private let zmLog = ZMSLog(tag: "EmoticonSubstitutionConfiguration")

final class EmoticonSubstitutionConfiguration {

    // Sorting keys is important. Longer keys should be resolved first,
    // In order to make 'O:-)' to be resolved as '😇', not a 'O😊'.
    lazy var shortcuts: [String] = {
        return substitutionRules.keys.sorted(by: {
            $0.count >= $1.count
        })
    }()

    // key is substitution string like ':)', value is smile string 😊
    let substitutionRules: [String: String]

    class var sharedInstance: EmoticonSubstitutionConfiguration {
        guard let filePath = Bundle.main.path(forResource: "emoticons.min", ofType: "json") else {
            fatal("emoticons.min does not exist!")
        }

        return EmoticonSubstitutionConfiguration(configurationFile: filePath)
    }

    init(configurationFile filePath: String) {
        let jsonResult: [String: String]?

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
            jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: String]
        } catch {
            zmLog.error("Failed to parse JSON at path: \(filePath), error: \(error)")
            fatal("\(error)")
        }

        substitutionRules = jsonResult?.mapValues { value -> String in
            if let hexInt = Int(value, radix: 16),
               let scalar = UnicodeScalar(hexInt) {
                return String(Character(scalar))
            }

            fatal("invalid value in dictionary")
        } ?? [:]
    }
}
