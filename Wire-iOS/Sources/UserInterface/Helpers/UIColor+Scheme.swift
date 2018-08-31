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

import Foundation

extension UIColor {

    static var textDimmed: UIColor {
        return UIColor(scheme: .textDimmed)
    }

    static var textForeground: UIColor {
        return UIColor(scheme: .textForeground)
    }

    static var textForegroundDark: UIColor {
        return UIColor(scheme: .textForeground, variant: .dark)
    }

    static var textBackground: UIColor {
        return UIColor(scheme: .textBackground)
    }

    static var background: UIColor {
        return UIColor(scheme: .background)
    }

    static var placeholderBackground: UIColor {
        return UIColor(scheme: .placeholderBackground)
    }

    static var separator: UIColor {
        return UIColor(scheme: .separator)
    }

    static var iconNormal: UIColor {
        return UIColor(scheme: .iconNormal)
    }

    static var iconNormalDark: UIColor {
        return UIColor(scheme: .iconNormal, variant: .dark)
    }

    static var iconHighlighted: UIColor {
        return UIColor(scheme: .iconHighlighted)
    }

    static var iconHighlightedDark: UIColor {
        return UIColor(scheme: .iconHighlighted, variant: .dark)
    }
}
