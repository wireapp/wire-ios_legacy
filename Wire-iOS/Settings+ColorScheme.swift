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

enum SettingsColorScheme {
    case light
    case dark
    
    var colorSchemeVariant: ColorSchemeVariant {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension Settings {
    func notifyColorSchemeChanged() {
        NotificationCenter.default.post(name: NSNotification.Name.SettingsColorSchemeChanged, object: self, userInfo: nil)
    }

    @objc
    var defaults: UserDefaults {
        return UserDefaults.standard
    }

    var colorScheme: SettingsColorScheme? {
        get {
            guard let string = defaults.string(forKey: UserDefaultColorScheme) else { return nil }
            
            return settingsColorScheme(from: string)
        }

        set {
            guard let colorScheme = colorScheme else { return }
            
            defaults.set(string(for: colorScheme), forKey: UserDefaultColorScheme)
            defaults.synchronize()
            notifyColorSchemeChanged()
        }
    }
    
    func settingsColorScheme(from string: String) -> SettingsColorScheme {
        switch string {
        case "dark":
            return .dark
        case "light":
            return .light
        default:
            fatal("unsupported colorScheme string")
        }
    }
    
    func string(for colorScheme: SettingsColorScheme) -> String {
        switch colorScheme {
        case .dark:
            return "dark"
        case .light:
            return "light"
        }
    }
}
