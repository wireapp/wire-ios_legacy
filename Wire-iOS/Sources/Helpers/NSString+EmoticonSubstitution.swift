//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
/*
- (void)resolveEmoticonShortcutsInRange:(NSRange)range
{
    EmoticonSubstitutionConfiguration *configuration = [EmoticonSubstitutionConfiguration sharedInstance];
    NSArray *shortcuts = configuration.shortcuts;
    for (NSString *shortcut in shortcuts) {
        NSString *emoticon = [configuration emoticonForShortcut:shortcut];
        NSUInteger howManyTimesReplaced = [self replaceOccurrencesOfString:shortcut
            withString:emoticon
            options:NSLiteralSearch
            range:range];
        if (howManyTimesReplaced) {
            range = NSMakeRange(range.location, MAX(range.length - (shortcut.length - emoticon.length) * howManyTimesReplaced,  0UL));
        }
    }
}
*/

extension String {
    func resolvingEmoticonShortcuts(configuration: EmoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration.sharedInstance()) -> String {
        let mutableString = NSMutableString(string: self)

        mutableString.resolveEmoticonShortcuts(in: NSRange(location: 0, length: count), configuration: configuration)

        return String(mutableString)
    }

    mutating func resolveEmoticonShortcuts(in range: NSRange,
                                  configuration: EmoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration.sharedInstance()) {
        let mutableString = NSMutableString(string: self)

        mutableString.resolveEmoticonShortcuts(in: range, configuration: configuration)

        self = String(mutableString)
//        return String(mutableString)
    }
}

extension NSMutableString {


    /// resolve emoticon shortcuts with given EmoticonSubstitutionConfiguration
    ///
    /// - Parameters:
    ///   - range: the range to resolve
    ///   - configuration: a EmoticonSubstitutionConfiguration object for injection
    func resolveEmoticonShortcuts(in range: NSRange,
                                  configuration: EmoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration.sharedInstance()) {
        guard let shortcuts = configuration.shortcuts as? [String] else { return }

        var mutableRange = range
//        var mutableSelf = NSMutableString(string: self)

        for shortcut in shortcuts {
            let emoticon = configuration.emoticon(forShortcut: shortcut)!

                        let emoticonNS = NSString(string: emoticon)
                        let shortcutNS = NSString(string: shortcut)

            let howManyTimesReplaced = (self as NSMutableString).replaceOccurrences(of: shortcut,
                                                          with: emoticon,
                                                          options: .literal,
                                                          range: mutableRange)



            if howManyTimesReplaced > 0 {
                let length = max(mutableRange.length - (shortcutNS.length - emoticonNS.length) * howManyTimesReplaced, 0)
                mutableRange = NSRange(location: mutableRange.location,
                                       length: length)
            }
        }

//        self = mutableSelf
    }
}
