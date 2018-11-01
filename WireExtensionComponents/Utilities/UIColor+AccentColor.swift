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
