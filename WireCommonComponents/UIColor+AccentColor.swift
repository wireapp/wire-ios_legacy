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
import WireDataModel
import UIKit

public enum AccentColor: Int16, CaseIterable {

    case blue = 1
    case green
    case yellow // Deprecated
    case red
    case amber
    case petrol
    case purple

    /// Returns a random accent color.
    public static var random: AccentColor {
        return AccentColor.allSelectable().randomElement()!
    }

    public init?(ZMAccentColor zmAccentColor: ZMAccentColor) {
        self.init(rawValue: zmAccentColor.rawValue)
    }

    public var zmAccentColor: ZMAccentColor {
        return ZMAccentColor(rawValue: self.rawValue)!
    }

    public static func allSelectable() -> [AccentColor] {
        return [.blue,
                .green,
                .red,
                .amber,
                .petrol,
                .purple]
    }

}

public extension UIColor {

    convenience init(for accentColor: AccentColor) {
        switch accentColor {
        case .blue:
            self.init(light: Asset.blue500Light, dark: Asset.blue500Dark)
        case .green:
            self.init(light: Asset.green500Light, dark: Asset.green500Dark)
        case .yellow: // Deprecated
            self.init(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        case .red:
            self.init(light: Asset.red500Light, dark: Asset.red500Dark)
        case .amber:
            self.init(light: Asset.amber500Light, dark: Asset.amber500Dark)
        case .petrol:
            self.init(light: Asset.petrol500Light, dark: Asset.petrol500Dark)
        case .purple:
            self.init(light: Asset.purple500Light, dark: Asset.purple500Dark)
        }
    }

    convenience init(fromZMAccentColor accentColor: ZMAccentColor) {
        let safeAccentColor = AccentColor(ZMAccentColor: accentColor) ?? .blue
        self.init(for: safeAccentColor)
    }

}
