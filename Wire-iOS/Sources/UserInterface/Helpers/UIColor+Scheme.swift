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

    static var background: UIColor {
        return UIColor.from(scheme: .background)
    }

    static var textPlaceholder: UIColor {
        return UIColor.from(scheme: .textPlaceholder)
    }

    static var placeholderBackground: UIColor {
        return UIColor.from(scheme: .placeholderBackground)
    }

    static var separator: UIColor {
        return UIColor.from(scheme: .separator)
    }

    static var iconNormal: UIColor {
        return UIColor.from(scheme: .iconNormal)
    }

    static var iconNormalDark: UIColor {
        return UIColor.from(scheme: .iconNormal, variant: .dark)
    }

    static var iconHighlighted: UIColor {
        return UIColor.from(scheme: .iconHighlighted)
    }

    static var iconHighlightedDark: UIColor {
        return UIColor.from(scheme: .iconHighlighted, variant: .dark)
    }

    static var contentBackground: UIColor {
        return UIColor.from(scheme: .contentBackground)
    }

    static var cellHighlight: UIColor {
        return UIColor.from(scheme: .cellHighlight)
    }
}
