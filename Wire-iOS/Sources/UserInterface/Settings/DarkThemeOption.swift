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

import Foundation

enum DarkThemeOption: Int {
    @available(iOS, introduced: 12.0, message: "auto only supported in iOS 12+")
    case auto
    case light
    case dark

    static var defaultPreference: DarkThemeOption {
        if #available(iOS 12.0, *) {
            return .auto
        } else {
            return .light
        }
    }

    var keyValueString: String {
        switch self {
        case .dark: return "dark"
        case .light: return "light"
        case .auto: return "auto"
        }
    }

    var displayString: String {
        return "dark_theme.option.\(keyValueString)".localized
    }

    static var allOptions: [DarkThemeOption] {
        if #available(iOS 12.0, *) {
            return [.dark, .light, .auto]
        } else {
            return [.dark, .light]
        }
    }

    init?(keyValueString: String) {
        switch keyValueString {
        case "dark":
            self = .dark
        case "light":
            self = .light
        case "auto":
            if #available(iOS 12.0, *) {
                self = .auto
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}
