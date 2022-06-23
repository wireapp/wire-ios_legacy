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
        static let closeButton          = UIColor(rgb: 0xDAD9DF)
        static let buttonHighlight      = SemanticColors.LegacyColors.strongBlue.withAlphaComponent(0.5)
        static let title                = UIColor(rgb: 0x323639)
        static let question             = UIColor.CallQuality.title.withAlphaComponent(0.56)
        static let score                = UIColor(rgb: 0x272A2C)
        static let scoreBackground      = UIColor(rgb: 0xF8F8F8)
        static let scoreHighlight       = SemanticColors.LegacyColors.strongBlue
    }
}
