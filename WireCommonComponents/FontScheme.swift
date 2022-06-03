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
import UIKit

public enum FontTextStyle: String {
    case largeTitle
    case inputText
}

public enum FontSize: String {
    case large
    case normal
    case medium
    case small
    case navBar
}

public enum FontWeight: String, CaseIterable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
}

@available(iOSApplicationExtension 8.2, *)
extension FontWeight {
    static let weightMapping: [FontWeight: UIFont.Weight] = [
        .ultraLight: UIFont.Weight.ultraLight,
        .thin: UIFont.Weight.thin,
        .light: UIFont.Weight.light,
        .regular: UIFont.Weight.regular,
        .medium: UIFont.Weight.medium,
        .semibold: UIFont.Weight.semibold,
        .bold: UIFont.Weight.bold,
        .heavy: UIFont.Weight.heavy,
        .black: UIFont.Weight.black
    ]

    /// Weight mapping used when the bold text accessibility setting is
    /// enabled. Light weight fonts won't render bold, so we use regular
    /// weights instead.
    static let accessibilityWeightMapping: [FontWeight: UIFont.Weight] = [
        .ultraLight: UIFont.Weight.regular,
        .thin: UIFont.Weight.regular,
        .light: UIFont.Weight.regular,
        .regular: UIFont.Weight.regular,
        .medium: UIFont.Weight.medium,
        .semibold: UIFont.Weight.semibold,
        .bold: UIFont.Weight.bold,
        .heavy: UIFont.Weight.heavy,
        .black: UIFont.Weight.black
    ]

    public func fontWeight(accessibilityBoldText: Bool? = nil) -> UIFont.Weight {
        let boldTextEnabled = accessibilityBoldText ?? UIAccessibility.isBoldTextEnabled
        let mapping = boldTextEnabled ? type(of: self).accessibilityWeightMapping : type(of: self).weightMapping
        return mapping[self]!
    }

    public init(weight: UIFont.Weight) {
        self = (type(of: self).weightMapping.filter {
            $0.value == weight
            }.first?.key) ?? FontWeight.regular
    }
}

extension UIFont {
    public static func systemFont(ofSize size: CGFloat, contentSizeCategory: UIContentSizeCategory, weight: FontWeight) -> UIFont {
        if #available(iOSApplicationExtension 8.2, *) {
            return self.systemFont(ofSize: round(size * UIFont.wr_preferredContentSizeMultiplier(for: contentSizeCategory)), weight: weight.fontWeight())
        } else {
            return self.systemFont(ofSize: round(size * UIFont.wr_preferredContentSizeMultiplier(for: contentSizeCategory)))
        }
    }
}

public struct FontSpec: Hashable {
    let size: FontSize
    public let weight: FontWeight?
    public let fontTextStyle: FontTextStyle?

    /// init method of FontSpec
    ///
    /// - Parameters:
    ///   - size: a FontSize enum
    ///   - weight: a FontWeight enum, if weight == nil, then apply the default value .light
    ///   - fontTextStyle: FontTextStyle enum value, if fontTextStyle == nil, then apply the default style.
    public init(_ size: FontSize, _ weight: FontWeight?, _ fontTextStyle: FontTextStyle? = .none) {
        self.size = size
        self.weight = weight
        self.fontTextStyle = fontTextStyle
    }

    public var font: UIFont? {
        return FontScheme.font(for: self)
    }
}

extension FontSpec: CustomStringConvertible {
    public var description: String {
        var descriptionString = "\(self.size)"

        if let weight = self.weight {
            descriptionString += "-\(weight)"
        }

        if let fontTextStyle = self.fontTextStyle {
            descriptionString += "-\(fontTextStyle.rawValue)"
        }

        return descriptionString
    }
}

public enum FontScheme {

    private typealias FontsByFontSpec = [FontSpec: UIFont]
    private typealias FontSizeAndPoint = (size: FontSize, point: CGFloat)

    private static var fontsByFontSpec = FontsByFontSpec()

    private static func mapFontTextStyleAndFontSizeAndPoint(fontSizeTuples allFontSizes: [FontSizeAndPoint],
                                                            mapping: inout [FontSpec: UIFont],
                                                            fontTextStyle: FontTextStyle,
                                                            contentSizeCategory: UIContentSizeCategory) {

        for weight in FontWeight.allCases {
            for (size, point) in allFontSizes {
                let nonWeightedSpec = FontSpec(size, .none, fontTextStyle)
                let weightedSpec = FontSpec(size, weight, fontTextStyle)

                mapping[nonWeightedSpec] = .systemFont(ofSize: point,
                                                       contentSizeCategory: contentSizeCategory,
                                                       weight: .light)

                mapping[weightedSpec] = .systemFont(ofSize: point,
                                                    contentSizeCategory: contentSizeCategory,
                                                    weight: weight)
            }
        }
    }

    public static func configure(with contentSizeCategory: UIContentSizeCategory) {
        fontsByFontSpec = FontsByFontSpec()
        
        // The ratio is following 11:12:16:24, same as default case
        let largeTitleFontSizeTuples: [FontSizeAndPoint] = [
            (size: .large, point: 40),
            (size: .normal, point: 26),
            (size: .medium, point: 20),
            (size: .small, point: 18)
        ]

        mapFontTextStyleAndFontSizeAndPoint(fontSizeTuples: largeTitleFontSizeTuples,
                                            mapping: &fontsByFontSpec,
                                            fontTextStyle: .largeTitle,
                                            contentSizeCategory: contentSizeCategory)

        let inputTextFontSizeTuples: [FontSizeAndPoint] = [
            (size: .large, point: 21),
            (size: .normal, point: 14),
            (size: .medium, point: 11),
            (size: .small, point: 10)
        ]

        mapFontTextStyleAndFontSizeAndPoint(fontSizeTuples: inputTextFontSizeTuples,
                                            mapping: &fontsByFontSpec,
                                            fontTextStyle: .inputText,
                                            contentSizeCategory: contentSizeCategory)

        /// fontTextStyle: none
        let navBarPointSize = pointSize(fontSize: .navBar, contentSizeCategory: contentSizeCategory)
        
        fontsByFontSpec[FontSpec(.navBar, .none, .none)]      = .systemFont(ofSize: navBarPointSize, weight: .light)
        fontsByFontSpec[FontSpec(.navBar, .bold, .none)]      = .systemFont(ofSize: navBarPointSize, weight: .bold)
        fontsByFontSpec[FontSpec(.navBar, .medium, .none)]    = .systemFont(ofSize: navBarPointSize, weight: .medium)
        fontsByFontSpec[FontSpec(.navBar, .semibold, .none)]  = .systemFont(ofSize: navBarPointSize, weight: .semibold)
        fontsByFontSpec[FontSpec(.navBar, .regular, .none)]   = .systemFont(ofSize: navBarPointSize, weight: .regular)
        fontsByFontSpec[FontSpec(.navBar, .light, .none)]     = .systemFont(ofSize: navBarPointSize, weight: .light)
        fontsByFontSpec[FontSpec(.navBar, .thin, .none)]      = .systemFont(ofSize: navBarPointSize, weight: .thin)
        
        let largePointSize = pointSize(fontSize: .large, contentSizeCategory: contentSizeCategory)
        
        fontsByFontSpec[FontSpec(.large, .none, .none)]      = .systemFont(ofSize: largePointSize, weight: .light)
        fontsByFontSpec[FontSpec(.large, .bold, .none)]      = .systemFont(ofSize: largePointSize, weight: .bold)
        fontsByFontSpec[FontSpec(.large, .medium, .none)]    = .systemFont(ofSize: largePointSize, weight: .medium)
        fontsByFontSpec[FontSpec(.large, .semibold, .none)]  = .systemFont(ofSize: largePointSize, weight: .semibold)
        fontsByFontSpec[FontSpec(.large, .regular, .none)]   = .systemFont(ofSize: largePointSize, weight: .regular)
        fontsByFontSpec[FontSpec(.large, .light, .none)]     = .systemFont(ofSize: largePointSize, weight: .light)
        fontsByFontSpec[FontSpec(.large, .thin, .none)]      = .systemFont(ofSize: largePointSize, weight: .thin)

        let normalPointSize = pointSize(fontSize: .normal, contentSizeCategory: contentSizeCategory)
        
        fontsByFontSpec[FontSpec(.normal, .none, .none)]      = .systemFont(ofSize: normalPointSize, weight: .light)
        fontsByFontSpec[FontSpec(.normal, .bold, .none)]      = .systemFont(ofSize: normalPointSize, weight: .bold)
        fontsByFontSpec[FontSpec(.normal, .medium, .none)]    = .systemFont(ofSize: normalPointSize, weight: .medium)
        fontsByFontSpec[FontSpec(.normal, .semibold, .none)]  = .systemFont(ofSize: normalPointSize, weight: .semibold)
        fontsByFontSpec[FontSpec(.normal, .regular, .none)]   = .systemFont(ofSize: normalPointSize, weight: .regular)
        fontsByFontSpec[FontSpec(.normal, .light, .none)]     = .systemFont(ofSize: normalPointSize, weight: .light)

        let mediumPointSize = pointSize(fontSize: .medium, contentSizeCategory: contentSizeCategory)
        
        fontsByFontSpec[FontSpec(.medium, .none, .none)]      = .systemFont(ofSize: mediumPointSize, weight: .light)
        fontsByFontSpec[FontSpec(.medium, .bold, .none)]      = .systemFont(ofSize: mediumPointSize, weight: .bold)
        fontsByFontSpec[FontSpec(.medium, .medium, .none)]    = .systemFont(ofSize: mediumPointSize, weight: .medium)
        fontsByFontSpec[FontSpec(.medium, .semibold, .none)]  = .systemFont(ofSize: mediumPointSize, weight: .semibold)
        fontsByFontSpec[FontSpec(.medium, .regular, .none)]   = .systemFont(ofSize: mediumPointSize, weight: .regular)
        fontsByFontSpec[FontSpec(.medium, .light, .none)]     = .systemFont(ofSize: mediumPointSize, weight: .light)

        let smallPointSize = pointSize(fontSize: .small, contentSizeCategory: contentSizeCategory)
        
        fontsByFontSpec[FontSpec(.small, .none, .none)]      = .systemFont(ofSize: smallPointSize, weight: .light)
        fontsByFontSpec[FontSpec(.small, .bold, .none)]      = .systemFont(ofSize: smallPointSize, weight: .bold)
        fontsByFontSpec[FontSpec(.small, .medium, .none)]    = .systemFont(ofSize: smallPointSize, weight: .medium)
        fontsByFontSpec[FontSpec(.small, .semibold, .none)]  = .systemFont(ofSize: smallPointSize, weight: .semibold)
        fontsByFontSpec[FontSpec(.small, .regular, .none)]   = .systemFont(ofSize: smallPointSize, weight: .regular)
        fontsByFontSpec[FontSpec(.small, .light, .none)]     = .systemFont(ofSize: smallPointSize, weight: .light)

    }

    public static func font(for fontType: FontSpec) -> UIFont? {
        return FontScheme.fontsByFontSpec[fontType]
    }
}

func pointSize(fontSize: FontSize, contentSizeCategory: UIContentSizeCategory) -> CGFloat {
    switch (fontSize, contentSizeCategory) {
    // SMALLL
    case (.small, .extraSmall):
        return 10
    case (.small, .small):
        return 10
    case (.small, .medium):
        return 11
    case (.small, .large):
        return 11
    case (.small, .extraLarge):
        return 13
    case (.small, .extraExtraLarge):
        return 15
    case (.small, .extraExtraExtraLarge):
        return 17
    case (.small, .accessibilityMedium):
        return 20
    case (.small, .accessibilityLarge):
        return 24
    case (.small, .accessibilityExtraLarge):
        return 29
    case (.small, .accessibilityExtraExtraLarge):
        return 34
    case (.small, .accessibilityExtraExtraExtraLarge):
        return 40
        
    // Normal
    case (.normal, .extraSmall):
        return 13
    case (.normal, .small):
        return 14
    case (.normal, .medium):
        return 15
    case (.normal, .large):
        return 16
    case (.normal, .extraLarge):
        return 18
    case (.normal, .extraExtraLarge):
        return 20
    case (.normal, .extraExtraExtraLarge):
        return 26
    case (.normal, .accessibilityMedium):
        return 32
    case (.normal, .accessibilityLarge):
        return 33
    case (.normal, .accessibilityExtraLarge):
        return 38
    case (.normal, .accessibilityExtraExtraLarge):
        return 44
    case (.normal, .accessibilityExtraExtraExtraLarge):
        return 51
        
    // Medium
    case (.medium, .extraSmall):
        return 11
    case (.medium, .small):
        return 11
    case (.medium, .medium):
        return 11
    case (.medium, .large):
        return 12
    case (.medium, .extraLarge):
        return 14
    case (.medium, .extraExtraLarge):
        return 16
    case (.medium, .extraExtraExtraLarge):
        return 18
    case (.medium, .accessibilityMedium):
        return 22
    case (.medium, .accessibilityLarge):
        return 26
    case (.medium, .accessibilityExtraLarge):
        return 32
    case (.medium, .accessibilityExtraExtraLarge):
        return 37
    case (.medium, .accessibilityExtraExtraExtraLarge):
        return 43
        
    // Large
    case (.large, .extraSmall):
        return 21
    case (.large, .small):
        return 22
    case (.large, .medium):
        return 23
    case (.large, .large):
        return 24
    case (.large, .extraLarge):
        return 27
    case (.large, .extraExtraLarge):
        return 29
    case (.large, .extraExtraExtraLarge):
        return 31
    case (.large, .accessibilityMedium):
        return 36
    case (.large, .accessibilityLarge):
        return 41
    case (.large, .accessibilityExtraLarge):
        return 46
    case (.large, .accessibilityExtraExtraLarge):
        return 50
    case (.large, .accessibilityExtraExtraExtraLarge):
        return 53
        
    // navBar
    case (.navBar, .extraSmall):
        return 13
    case (.navBar, .small):
        return 14
    case (.navBar, .medium):
        return 15
    case (.navBar, .large):
        return 16
    case (.navBar, .extraLarge):
        return 17
    case (.navBar, .extraExtraLarge):
        return 18
    case (.navBar, .extraExtraExtraLarge):
        return 20
    case (.navBar, .accessibilityMedium):
        return 22
    case (.navBar, .accessibilityLarge):
        return 24
    case (.navBar, .accessibilityExtraLarge):
        return 28
    case (.navBar, .accessibilityExtraExtraLarge):
        return 29
    case (.navBar, .accessibilityExtraExtraExtraLarge):
        return 30
        
    default:
        return 10
    }
}
