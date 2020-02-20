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

private let zmLog = ZMSLog(tag: "EmoticonSubstitutionConfiguration")

final class EmoticonSubstitutionConfiguration {
    
    // Sorting keys is important. Longer keys should be resolved first,
    // In order to make 'O:-)' to be resolved as '😇', not a 'O😊'.
    private(set) lazy var shortcuts: [String]? = {
        return substitutionRules?.keys.sorted(by: { (obj1: String, obj2: String) -> Bool in
            if obj1.count > obj2.count {
                return true
            } /*else if obj1.count < obj2.count {
             return .orderedDescending
             }*/
            
            return false
        })
    }()
    
    // key is substitution string like ':)', value is smile string 😊
    private var substitutionRules: [String : String]?
    
    class var sharedInstance: EmoticonSubstitutionConfiguration {
        guard let filePath = Bundle.main.path(forResource: "emoticons.min", ofType: "json") else {
                fatal("emoticons.min not exist!")
        }
        
        return EmoticonSubstitutionConfiguration(configurationFile: filePath)
    }
    
    init(configurationFile filePath: String) {

        
        let jsonResult: [String : String]!

            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
                jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String : String]
            } catch {
                zmLog.error("Failed to parse JSON at path: \(filePath), error: \(error)")
                fatal("\(error)")
            }
        
        var rules: [String: String] = [:]
        for (key, value) in jsonResult {
            let hexInt = Int(value, radix: 16)!
            let scalar = UnicodeScalar(hexInt)!
            rules[key] = String(Character(scalar))
        }

        substitutionRules = rules
    }
    
    func emoticon(forShortcut shortcut: String) -> String? {
        return substitutionRules?[shortcut]
    }

}
