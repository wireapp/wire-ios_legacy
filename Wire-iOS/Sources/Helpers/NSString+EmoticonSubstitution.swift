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

extension NSMutableString {


    /// resolve emoticon shortcuts with given EmoticonSubstitutionConfiguration
    ///
    /// - Parameters:
    ///   - range: the range to resolve
    ///   - configuration: a EmoticonSubstitutionConfiguration object for injection
    func resolveEmoticonShortcuts(in range: NSRange,
                                  configuration: EmoticonSubstitutionConfiguration = EmoticonSubstitutionConfiguration.sharedInstance()) {
        guard let shortcuts = configuration.shortcuts as? [NSString] else { return }

        var mutableRange = range

        for shortcut in shortcuts {
            let emoticon = NSString(string: configuration.emoticon(forShortcut: shortcut as String))

            let howManyTimesReplaced = (self as NSMutableString).replaceOccurrences(of: shortcut as String,
                                                                                    with: emoticon as String,
                                                                                    options: .literal,
                                                                                    range: mutableRange)



            if howManyTimesReplaced > 0 {
                let length = max(mutableRange.length - (shortcut.length - emoticon.length) * howManyTimesReplaced, 0)
                mutableRange = NSRange(location: mutableRange.location,
                                       length: length)
            }
        }
    }
}
