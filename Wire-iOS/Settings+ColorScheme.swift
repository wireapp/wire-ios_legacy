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
import UIKit

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
    
    init(from string: String) {
        switch string {
        case "dark":
            self = .dark
        case "light":
            self = .light
        case "auto":
            if #available(iOS 12.0, *) {
                switch UIApplication.userInterfaceStyle {
                case .light:
                    self = .light
                case .dark:
                    self = .dark
                default:
                    self = .light
                }
            } else {
                fatal("auto only supported in iOS 12+")
            }
        default:
            fatal("unsupported colorScheme string")
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

        return SettingsColorScheme(from: string).colorSchemeVariant
    }
}
