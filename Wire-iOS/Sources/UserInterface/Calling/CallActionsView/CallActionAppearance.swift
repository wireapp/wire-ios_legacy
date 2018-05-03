//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

enum CallActionAppearance {
    case light, dark
    
    var backgroundColorNormal: UIColor {
        switch self {
        case .light: return UIColor.wr_color(fromColorScheme: ColorSchemeColorGraphite, variant: .light).withAlphaComponent(0.08)
        case .dark: return UIColor.white.withAlphaComponent(0.24)
        }
    }
    
    var backgroundColorSelected: UIColor {
        switch self {
        case .light: return .wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .light)
        case .dark: return .wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .dark)
        }
    }
    
    var iconColorNormal: UIColor {
        switch self {
        case .light: return .wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .light)
        case .dark: return .wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .dark)
        }
    }
    
    var iconColorSelected: UIColor {
        switch self {
        case .light: return .wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .dark)
        case .dark: return .wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .light)
        }
    }
}
