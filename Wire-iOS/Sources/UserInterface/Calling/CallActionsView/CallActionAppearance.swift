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

import UIKit

enum CallActionAppearance: Equatable {
    case light, dark(blurred: Bool), adaptive

    var showBlur: Bool {
        switch self {
        case .light, .adaptive: return false
        case .dark(blurred: let blurred): return blurred
        }
    }

    var backgroundColorNormal: UIColor {
        switch self {
        case .light: return UIColor.lightGraphite.withAlphaComponent(0.08)
        case .dark: return UIColor.white.withAlphaComponent(0.24)
        case .adaptive: return UIColor.from(scheme: .callIconBackground, variant: ColorScheme.default.variant)
        }
    }

    var backgroundColorSelected: UIColor {
        switch self {
        case .light: return UIColor.from(scheme: .iconNormal, variant: .light)
        case .dark: return UIColor.from(scheme: .iconNormal, variant: .dark)

            case .adaptive: return UIColor.from(scheme: .callIconBackgroundSelected, variant: ColorScheme.default.variant)
        }
    }

    var iconColorNormal: UIColor {
        switch self {
        case .light: return UIColor.from(scheme: .iconNormal, variant: .light)
        case .dark: return UIColor.from(scheme: .iconNormal, variant: .dark)
        case .adaptive: return UIColor.from(scheme: .callIconNormal, variant: ColorScheme.default.variant)
        }
    }

    var iconColorSelected: UIColor {
        switch self {
        case .light: return UIColor.from(scheme: .iconNormal, variant: .dark)
        case .dark: return UIColor.from(scheme: .iconNormal, variant: .light)
        case .adaptive: return UIColor.from(scheme: .callIconSelected, variant: ColorScheme.default.variant)
        }
    }


    var backgroundColorDisabled: UIColor {
        switch self {
        case .light: return UIColor.black.withAlphaComponent(0.16)
        case .dark: return UIColor.white.withAlphaComponent(0.4)
        case .adaptive: return UIColor.from(scheme: .callIconBackgroundDisabled, variant: ColorScheme.default.variant)
        }
    }


    var iconColorDisabled: UIColor {
        switch self {
        case .light: return UIColor.black.withAlphaComponent(0.16)
        case .dark: return UIColor.white.withAlphaComponent(0.4)
        case .adaptive: return UIColor.from(scheme: .callIconDisabled, variant: ColorScheme.default.variant)
        }
    }


    var backgroundColorSelectedAndHighlighted: UIColor {
        switch self {
        case .light: return UIColor.black.withAlphaComponent(0.16)
        case .dark: return UIColor.white.withAlphaComponent(0.4)
        case .adaptive: return UIColor.from(scheme: .callIconBackgroundDisabled, variant: ColorScheme.default.variant)
        }
    }
}
