//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCommonComponents

extension AccentColor {
    var name: String {
        typealias AccentColor = L10n.Localizable.Self.Settings.AccountPictureGroup.AccentColor
        switch self {
        case .blue:
            return AccentColor.blue
        case .green:
            return AccentColor.green
        case .yellow:
            return AccentColor.yellow
        case .red:
            return AccentColor.red
        case .amber:
            return AccentColor.amber
        case .petrol:
            return AccentColor.petrol
        case .purple:
            return AccentColor.purple
        }
    }
}
