//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit

enum SettingsColorScheme: Int, CaseIterable {
    
    case light = 0
    case dark = 1
    case system = 2

    var colorSchemeVariant: ColorSchemeVariant {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return UIApplication.userInterfaceStyle == .dark ? .dark : .light
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }

    init(from string: String?) {
        switch string {
        case "dark":
            self = .dark
        case "light":
            self = .light
        case "system":
            self = .system
        default:
            self = SettingsColorScheme.defaultPreference
        }
    }

    static var defaultPreference: SettingsColorScheme {
        return .system
    }

    var keyValueString: String {
        switch self {
        case .dark: return "dark"
        case .light: return "light"
        case .system: return "system"
        }
    }

    var displayString: String {
        return "dark_theme.option.\(keyValueString)".localized
    }
}

extension Settings {

    var colorSchemeVariant: ColorSchemeVariant {
        guard let string: String = self[.colorScheme] else {
            return SettingsColorScheme.defaultPreference.colorSchemeVariant
        }

        return SettingsColorScheme(from: string).colorSchemeVariant
    }

    var colorScheme: SettingsColorScheme {
        guard let string: String = self[.colorScheme] else {
            return SettingsColorScheme.defaultPreference
        }

        return SettingsColorScheme(from: string)
    }

}
