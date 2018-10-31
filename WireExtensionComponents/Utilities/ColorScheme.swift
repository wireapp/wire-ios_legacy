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
import UIKit

enum Colours {
    static var graphite: UIColor = UIColor.wr_color(from: "rgb(51, 55, 58)")
    static var lightGraphite: UIColor = UIColor.wr_color(from: "rgb(141, 152, 159)")
}

@objc public enum ColorSchemeColor: Int {
    case textForeground
    case textBackground
    case textDimmed
    case textPlaceholder

    case iconNormal
    case iconSelected
    case iconHighlighted
    case iconBackgroundSelected
    case iconBackgroundSelectedNoAccent
    case iconShadow
    case iconHighlight
    case iconGuest

    case popUpButtonOverlayShadow

    case buttonHighlighted
    case buttonFaded

    case tabNormal
    case tabSelected
    case tabHighlighted

    case background
    case contentBackground
    case barBackground
    case searchBarBackground
    case separator
    case cellSeparator
    case backgroundOverlay
    case backgroundOverlayWithoutPicture
    case placeholderBackground
    case avatarBorder
    case loadingDotActive
    case loadingDotInactive

    case paleSeparator
    case listAvatarInitials
    case audioButtonOverlay

    case nameAccentPrefix

    case graphite
    case lightGraphite

    case sectionBackground
    case sectionText

    case tokenFieldBackground
    case tokenFieldTextPlaceHolder

    case selfMentionHighlight
}

extension UIColor {
    convenience public init(scheme: ColorSchemeColor) {
        self.init(cgColor: scheme.colorPair.light.cgColor)
    }

    convenience public init(scheme: ColorSchemeColor, variant: ColorSchemeVariant) {
        switch variant {
        case .light:
            self.init(cgColor: scheme.colorPair.light.cgColor)
        case .dark:
            self.init(cgColor: scheme.colorPair.dark.cgColor)
        }
    }

}

extension ColorSchemeColor {
    typealias ColourPair = (light: UIColor, dark: UIColor)

    fileprivate var colorPair: ColourPair  {
        switch self {
        case .textForeground:
            return (light: Colours.graphite, dark: Colours.lightGraphite)
        default:
            return (light: .black, dark: .white)
        }
    }
}

fileprivate extension ZMAccentColor {
    var name: String {
        switch self {
        case .undefined:
            return "undefined"
        case .strongBlue:
            return "strong-blue"
        case .strongLimeGreen:
            return "strong-lime-green"
        case .brightYellow:
            return "bright-yellow"
        case .vividRed:
            return "vivid-red"
        case .brightOrange:
            return "bright-orange"
        case .softPink:
            return "soft-pink"
        case .violet:
            return "violet"
        default:
            fatalError("Invalid accent color")
        }
    }
}

public extension ColorScheme {
    @objc(colorWithName:)
    public func color(named: ColorSchemeColor) -> UIColor {
        return color(named: named, variant: variant)
    }

    @objc(colorWithName:variant:)
    public func color(named: ColorSchemeColor, variant: ColorSchemeVariant) -> UIColor {
        let colorPair = named.colorPair
        switch variant {
        case .dark:
            return colorPair.dark
        case .light:
            return colorPair.light
        }
    }

    @objc(nameAccentForColor:variant:)
    public func nameAccent(for color: ZMAccentColor, variant: ColorSchemeVariant) -> UIColor {
//        let colourName = ColorSchemeColor(rawValue: "name-accent-" + color.name)
//        return self.color(named: colourName, variant: variant)
        return .black
    }

}
