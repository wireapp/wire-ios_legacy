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

extension UIColor {
    enum CallQuality {
        static let backgroundDim        = UIColor.black.withAlphaComponent(0.6)
        static let contentBackground    = UIColor.white
        static let closeButton          = UIColor.cas_color(withHex: "#DAD9DF")!
        static let buttonHighlight      = UIColor(for: .strongBlue).withAlphaComponent(0.5)
        static let title                = UIColor.cas_color(withHex: "#323639")!
        static let question             = UIColor.CallQuality.title.withAlphaComponent(0.56)
        static let score                = UIColor.cas_color(withHex: "#272A2C")!
        static let scoreBackground      = UIColor.cas_color(withHex: "#F8F8F8")!
        static let scoreHighlight       = UIColor(for: .strongBlue)!
    }
}
