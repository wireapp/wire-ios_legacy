//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension UIFont {

    public enum FontStyle {
        case title3
        case headline
        case body
        case subheadline
        case caption1
        case title3Bold
        case calloutBold
        case footnoteSemibold
        case bodyTwoSemibold

    }

    public static func font(for style: FontStyle) -> UIFont {
        switch style {

        case .title3:
            return .preferredFont(forTextStyle: .title3)

        case .headline:
            return .preferredFont(forTextStyle: .headline)

        case .body:
            return .preferredFont(forTextStyle: .body)

        case .subheadline:
            return .preferredFont(forTextStyle: .subheadline)

        case .caption1:
            return .preferredFont(forTextStyle: .caption1)

        case .title3Bold:
            return .preferredFont(forTextStyle: .title3).fontWeight(.bold)

        case .calloutBold:
            return .preferredFont(forTextStyle: .callout).fontWeight(.bold)

        case .footnoteSemibold:
            return .preferredFont(forTextStyle: .footnote).fontWeight(.semibold)

        case .bodyTwoSemibold:
            return  .systemFont(ofSize: 16, weight: .semibold)
        }
    }


    /// Returns a new font with the weight specified
    ///
    /// - Parameter weight: The new font weight
    public func fontWeight(_ weight: UIFont.Weight) -> UIFont {
        let fontDescriptor = UIFontDescriptor(fontAttributes: [
            UIFontDescriptor.AttributeName.size: pointSize,
            UIFontDescriptor.AttributeName.family: familyName
        ])

        // Add the font weight to the descriptor
        let weightedFontDescriptor = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight
            ]
        ])
        return UIFont(descriptor: weightedFontDescriptor, size: 0)
    }
}
