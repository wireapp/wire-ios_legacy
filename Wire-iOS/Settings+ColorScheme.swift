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
import WireSystem

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
    var defaults: UserDefaults {
        return .standard
    }

    var colorSchemeVariant: ColorSchemeVariant {
        guard let string: String = self[.colorScheme] else {
            return .light
        }

        return settingsColorScheme(from: string).colorSchemeVariant
    }

    ///TODO: move to SettingsColorScheme, as a init method
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

    ///TODO: move to SettingsColorScheme
    func string(for colorScheme: SettingsColorScheme) -> String {
        switch colorScheme {
        case .dark:
            return "dark"
        case .light:
            return "light"
        }
    }
}
