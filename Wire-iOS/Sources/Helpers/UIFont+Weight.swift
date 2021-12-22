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

public extension UIFont {

    /// Returns a font object that is the same as the receiver but which has the specified weight
    func withWeight(_ weight: Weight) -> UIFont {

        // Remove bold trait since we will modify the weight
        var symbolicTraits = fontDescriptor.symbolicTraits
        symbolicTraits.remove(.traitBold)

        var traits = fontDescriptor.fontAttributes[.traits] as? [String: Any] ?? [:]
        traits[kCTFontWeightTrait as String] = weight
        traits[kCTFontSymbolicTrait as String] = symbolicTraits.rawValue

        var fontAttributes: [UIFontDescriptor.AttributeName: Any] = [:]
        fontAttributes[.family] = familyName
        fontAttributes[.traits] = traits

        return UIFont(descriptor: UIFontDescriptor(fontAttributes: fontAttributes), size: pointSize)
    }

}
