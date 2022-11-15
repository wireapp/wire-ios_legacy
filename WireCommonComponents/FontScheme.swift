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
    case header
    case titleThree
    case subHeadline
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

        fontsByFontSpec[FontSpec(.large, .none, .none)]      = .systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        fontsByFontSpec[FontSpec(.large, .medium, .none)]    = .systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .medium)
        fontsByFontSpec[FontSpec(.large, .semibold, .none)]  = .systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .semibold)
        fontsByFontSpec[FontSpec(.large, .regular, .none)]   = .systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .regular)
        fontsByFontSpec[FontSpec(.large, .light, .none)]     = .systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        fontsByFontSpec[FontSpec(.large, .thin, .none)]      = .systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .thin)

        fontsByFontSpec[FontSpec(.normal, .none, .none)]     = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        fontsByFontSpec[FontSpec(.normal, .light, .none)]    = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        fontsByFontSpec[FontSpec(.normal, .thin, .none)]     = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .thin)
        fontsByFontSpec[FontSpec(.normal, .regular, .none)]  = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .regular)
        fontsByFontSpec[FontSpec(.normal, .semibold, .none)] = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .semibold)
        fontsByFontSpec[FontSpec(.normal, .medium, .none)]   = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .medium)
        fontsByFontSpec[FontSpec(.normal, .bold, .none)]     = .systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .bold)

        fontsByFontSpec[FontSpec(.medium, .none, .none)]     = .systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .light)
        fontsByFontSpec[FontSpec(.medium, .bold, .none)]     = .systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .bold)
        fontsByFontSpec[FontSpec(.medium, .medium, .none)]   = .systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .medium)
        fontsByFontSpec[FontSpec(.medium, .semibold, .none)] = .systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .semibold)
        fontsByFontSpec[FontSpec(.medium, .regular, .none)]  = .systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .regular)

        fontsByFontSpec[FontSpec(.small, .none, .none)]      = .systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)
        fontsByFontSpec[FontSpec(.small, .bold, .none)]      = .systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .bold)
        fontsByFontSpec[FontSpec(.small, .medium, .none)]    = .systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .medium)
        fontsByFontSpec[FontSpec(.small, .semibold, .none)]  = .systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .semibold)
        fontsByFontSpec[FontSpec(.small, .regular, .none)]   = .systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .regular)
        fontsByFontSpec[FontSpec(.small, .light, .none)]     = .systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)

        fontsByFontSpec[FontSpec(.header, .semibold, .none)] = .systemFont(ofSize: 17, contentSizeCategory: contentSizeCategory, weight: .semibold)
        fontsByFontSpec[FontSpec(.header, .regular, .none)] = .systemFont(ofSize: 17, contentSizeCategory: contentSizeCategory, weight: .regular)

        fontsByFontSpec[FontSpec(.titleThree, .semibold, .none)] = .systemFont(ofSize: 20, contentSizeCategory: contentSizeCategory, weight: .semibold)
        fontsByFontSpec[FontSpec(.subHeadline, .regular, .none)] = .systemFont(ofSize: 15, contentSizeCategory: contentSizeCategory, weight: .regular)

    }

    public static func font(for fontType: FontSpec) -> UIFont? {
        return FontScheme.fontsByFontSpec[fontType]
    }
}
