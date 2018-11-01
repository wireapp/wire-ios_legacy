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

extension UIColor {
    static var graphite: UIColor = UIColor.wr_color(from: "rgb(51, 55, 58)")
    static var graphiteAlpha8: UIColor = UIColor.wr_color(from: "rgb(51, 55, 58, 0.08)")
    static var graphiteAlpha16: UIColor = UIColor.wr_color(from: "rgb(51, 55, 58, 0.16)")
    static var graphiteAlpha40: UIColor = UIColor.wr_color(from: "rgb(51, 55, 58, 0.4)")

    static var backgroundLightGraphite: UIColor = UIColor.wr_color(from: "rgb(30, 32, 33)")

    static var lightGraphite: UIColor = UIColor.wr_color(from: "rgb(141, 152, 159)")
    static var lightGraphiteAlpha8: UIColor = UIColor.wr_color(from: "rgb(141, 152, 159, 0.08)")
    static var lightGraphiteAlpha24: UIColor = UIColor.wr_color(from: "rgb(141, 152, 159, 0.24)")
    static var lightGraphiteAlpha48: UIColor = UIColor.wr_color(from: "rgb(141, 152, 159, 0.48)")
    static var lightGraphiteAlpha64: UIColor = UIColor.wr_color(from: "rgb(141, 152, 159, 0.64)")

    static var backgroundGraphite: UIColor = UIColor.wr_color(from: "rgb(22, 24, 25)")
    static var backgroundGraphiteAlpha40: UIColor = UIColor.wr_color(from: "rgb(22, 24, 25, 0.4)")

    static var white97: UIColor = UIColor(white: 0.97, alpha: 1)
    static var white98: UIColor = UIColor(white: 0.98, alpha: 1)

    static var whiteAlpha8: UIColor = UIColor(white: 1.0, alpha: 0.08)
    static var whiteAlpha16: UIColor = UIColor(white: 1.0, alpha: 0.16)
    static var whiteAlpha24: UIColor = UIColor(white: 1.0, alpha: 0.24)
    static var whiteAlpha40: UIColor = UIColor(white: 1.0, alpha: 0.4)
    static var whiteAlpha56: UIColor = UIColor(white: 1.0, alpha: 0.56)
    static var whiteAlpha64: UIColor = UIColor(white: 1.0, alpha: 0.64)
    static var whiteAlpha80: UIColor = UIColor(white: 1.0, alpha: 0.8)

    static var blackAlpha4: UIColor = UIColor(white: 0.0, alpha: 0.04)
    static var blackAlpha8: UIColor = UIColor(white: 0.0, alpha: 0.08)
    static var blackAlpha24: UIColor = UIColor(white: 0.0, alpha: 0.24)
    static var blackAlpha48: UIColor = UIColor(white: 0.0, alpha: 0.48)
    static var blackAlpha40: UIColor = UIColor(white: 0.0, alpha: 0.4)
    static var blackAlpha80: UIColor = UIColor(white: 0.0, alpha: 0.8)

    static var amberAlpha48: UIColor = UIColor.wr_color(from: "rgb(254, 191, 2, 0.48)")
    static var amberAlpha80: UIColor = UIColor.wr_color(from: "rgb(254, 191, 2, 0.8)")

}

public extension UIColor {
    @objc public convenience init?(for accentColor: ZMAccentColor) {
        switch accentColor {
        case .strongBlue:
            self.init(red: 0.141, green: 0.552, blue: 0.827, alpha: 1)
        case .strongLimeGreen:
            self.init(red: 0, green: 0.784, blue: 0, alpha: 1)
        case .brightYellow:
            self.init(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        case .vividRed:
            self.init(red: 1, green: 0.152, blue: 0, alpha: 1)
        case .brightOrange:
            self.init(red: 1, green: 0.537, blue: 0, alpha: 1)
        case .softPink:
            self.init(red: 0.996, green: 0.368, blue: 0.741, alpha:1)
        case .violet:
            self.init(red: 0.615, green: 0, blue: 1, alpha: 1)
        default:
            return nil
        }
    }
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
    case buttonEmptyText
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
        self.init(cgColor: ColorScheme.default.color(named: scheme).cgColor)
    }

    convenience public init(scheme: ColorSchemeColor, variant: ColorSchemeVariant) {
        self.init(cgColor: ColorScheme.default.color(named: scheme, variant: variant).cgColor)
    }

}

struct ColourPair {
    let light: UIColor
    let dark: UIColor
}

extension ColourPair {
    init(both color: UIColor) {
        self.init(light: color, dark: color)
    }
}

extension ColorSchemeColor {

    fileprivate func colorPair(accentColor: UIColor) -> ColourPair  {
        switch self {
        case .textForeground:
            return ColourPair(light: .graphite, dark: .white)
        case .textBackground:
            return ColourPair(light: .white, dark: .backgroundGraphite)
        case .textDimmed:
            return ColourPair(both: .lightGraphite)
        case .textPlaceholder:
            return ColourPair(both: .lightGraphiteAlpha64)
        case .separator:
            return ColourPair(light: .lightGraphiteAlpha48, dark: .lightGraphiteAlpha24)
        case .barBackground:
            return ColourPair(light: .white, dark: .backgroundLightGraphite)
        case .background:
            return ColourPair(light: .white, dark: .backgroundGraphite)
        case .contentBackground:
            return ColourPair(light: .white97, dark: .backgroundGraphite)
        case .iconNormal:
            return ColourPair(light: .graphite, dark: .white)
        case .iconSelected:
            return ColourPair(light: .white, dark: .black)
        case .iconHighlighted:
            return ColourPair(both: .white)
        case .iconShadow:
            return ColourPair(light: .blackAlpha8, dark: .blackAlpha24)
        case .iconHighlight:
            return ColourPair(light: .white, dark: .whiteAlpha16)
        case .iconBackgroundSelected:
            return ColourPair(light: accentColor, dark: .white)
        case .iconBackgroundSelectedNoAccent:
            return ColourPair(light: .graphite, dark: .white)
        case .popUpButtonOverlayShadow:
            return ColourPair(light: .blackAlpha24, dark: .black)
        case .buttonHighlighted:
            return ColourPair(light: .whiteAlpha24, dark: .blackAlpha24)
        case .buttonEmptyText:
            return ColourPair(light: accentColor, dark: .white)
        case .buttonFaded:
            return ColourPair(light: .graphiteAlpha40, dark: .whiteAlpha40)
        case .tabNormal:
            return ColourPair(light: .blackAlpha48, dark: .whiteAlpha56)
        case .tabSelected:
            return ColourPair(light: .graphite, dark: .white)
        case .tabHighlighted:
            return ColourPair(light: .lightGraphite, dark: .lightGraphiteAlpha48)
        case .backgroundOverlay:
            return ColourPair(light: .blackAlpha24, dark: .blackAlpha48)
        case .backgroundOverlayWithoutPicture:
            return ColourPair(both: .blackAlpha80)
        case .avatarBorder:
            return ColourPair(light: .blackAlpha8, dark: .whiteAlpha16)
        case .audioButtonOverlay:
            return ColourPair(both: .lightGraphiteAlpha24)
        case .placeholderBackground:
            let light = UIColor.lightGraphiteAlpha8.removeAlphaByBlending(with: .white98)!
            let dark = UIColor.lightGraphiteAlpha8.removeAlphaByBlending(with: .backgroundGraphite)!
            return ColourPair(light: light, dark: dark)
        case .loadingDotActive:
            return ColourPair(light: .graphiteAlpha40, dark: .whiteAlpha40)
        case .loadingDotInactive:
            return ColourPair(light: .graphiteAlpha16, dark: .whiteAlpha16)
        case .graphite:
            return ColourPair(both: .graphite)
        case .lightGraphite:
            return ColourPair(both: .lightGraphite)
        case .paleSeparator:
            return ColourPair(both: .lightGraphiteAlpha24)
        case .listAvatarInitials:
            return ColourPair(both: .blackAlpha40)
        case .sectionBackground:
            return ColourPair(both: .clear)
        case .sectionText:
            return ColourPair(light: .blackAlpha40, dark: .whiteAlpha40)
        case .tokenFieldBackground:
            return ColourPair(light: .blackAlpha4, dark: .whiteAlpha16)
        case .tokenFieldTextPlaceHolder:
            return ColourPair(light: .lightGraphite, dark: .whiteAlpha40)
        case .cellSeparator:
            return ColourPair(light: .graphiteAlpha8, dark: .whiteAlpha8)
        case .searchBarBackground:
            return ColourPair(light: .white, dark: .whiteAlpha8)
        case .iconGuest:
            return ColourPair(light: .backgroundGraphiteAlpha40, dark: .whiteAlpha64)
        case .selfMentionHighlight:
            return ColourPair(light: .amberAlpha48, dark: .amberAlpha80)
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
        let colorPair = named.colorPair(accentColor: accentColor)
        switch variant {
        case .dark:
            return colorPair.dark
        case .light:
            return colorPair.light
        }
    }

    @objc(nameAccentForColor:variant:)
    public func nameAccent(for color: ZMAccentColor, variant: ColorSchemeVariant) -> UIColor {
        return UIColor.nameColor(for: color, variant: variant)
    }

}
