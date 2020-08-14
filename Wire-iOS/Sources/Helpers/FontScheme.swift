//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
    case largeTitle  = "largeTitle"
    case inputText   = "inputText"
}

enum FontSize: String {
    case large  = "large"
    case normal = "normal"
    case medium = "medium"
    case small  = "small"
}

public enum FontWeight: String {
    case ultraLight = "ultraLight"
    case thin     = "thin"
    case light    = "light"
    case regular  = "regular"
    case medium   = "medium"
    case semibold = "semibold"
    case bold     = "bold"
    case heavy    = "heavy"
    case black    = "black"
}

@available(iOSApplicationExtension 8.2, *)
extension FontWeight {
    static let weightMapping: [FontWeight: UIFont.Weight] = [
        .ultraLight: UIFont.Weight.ultraLight,
        .thin:       UIFont.Weight.thin,
        .light:      UIFont.Weight.light,
        .regular:    UIFont.Weight.regular,
        .medium:     UIFont.Weight.medium,
        .semibold:   UIFont.Weight.semibold,
        .bold:       UIFont.Weight.bold,
        .heavy:      UIFont.Weight.heavy,
        .black:      UIFont.Weight.black
    ]
    
    /// Weight mapping used when the bold text accessibility setting is
    /// enabled. Light weight fonts won't render bold, so we use regular
    /// weights instead.
    static let accessibilityWeightMapping: [FontWeight: UIFont.Weight] = [
        .ultraLight: UIFont.Weight.regular,
        .thin:       UIFont.Weight.regular,
        .light:      UIFont.Weight.regular,
        .regular:    UIFont.Weight.regular,
        .medium:     UIFont.Weight.medium,
        .semibold:   UIFont.Weight.semibold,
        .bold:       UIFont.Weight.bold,
        .heavy:      UIFont.Weight.heavy,
        .black:      UIFont.Weight.black
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
    init(_ size: FontSize, _ weight: FontWeight?, _ fontTextStyle: FontTextStyle? = .none) {
        self.size = size
        self.weight = weight
        self.fontTextStyle = fontTextStyle
    }
}

extension FontSpec {
    var fontWithoutDynamicType: UIFont? {
        return FontScheme(contentSizeCategory: .medium).font(for: self)
    }
}

#if !swift(>=4.2)

extension FontSpec {
    public var hashValue: Int {
        return self.size.hashValue &* 1000 &+ (self.weight?.hashValue ?? 100)
    }
}

#endif

extension FontSpec: CustomStringConvertible {
    public var description: String {
        get {
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
}

public func==(left: FontSpec, right: FontSpec) -> Bool {
    return left.size == right.size && left.weight == right.weight && left.fontTextStyle == right.fontTextStyle
}

final class FontScheme {
    public typealias FontMapping = [FontSpec: UIFont]
    
    public var fontMapping: FontMapping = [:]
    
    fileprivate static func mapFontTextStyleAndFontSizeAndPoint(fontSizeTuples allFontSizes: [(fontSize: FontSize, point: CGFloat)], mapping: inout [FontSpec : UIFont], fontTextStyle: FontTextStyle, contentSizeCategory: UIContentSizeCategory) {
        let allFontWeights: [FontWeight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        for fontWeight in allFontWeights {
            for fontSizeTuple in allFontSizes {
                mapping[FontSpec(fontSizeTuple.fontSize, .none, fontTextStyle)]      = UIFont.systemFont(ofSize: fontSizeTuple.point, contentSizeCategory: contentSizeCategory, weight: .light)

                mapping[FontSpec(fontSizeTuple.fontSize, fontWeight, fontTextStyle)] = UIFont.systemFont(ofSize: fontSizeTuple.point, contentSizeCategory: contentSizeCategory, weight: fontWeight)
            }
        }
    }

    public static func defaultFontMapping(with contentSizeCategory: UIContentSizeCategory) -> FontMapping {
        var mapping: FontMapping = [:]


        // The ratio is following 11:12:16:24, same as default case
        let largeTitleFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large,  point: 40),
                                                                                (fontSize: .normal, point: 26),
                                                                                (fontSize: .medium, point: 20),
                                                                                (fontSize: .small,  point: 18)]
        mapFontTextStyleAndFontSizeAndPoint(fontSizeTuples: largeTitleFontSizeTuples, mapping: &mapping, fontTextStyle: .largeTitle, contentSizeCategory: contentSizeCategory)


        let inputTextFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large,  point: 21),
                                                                               (fontSize: .normal, point: 14),
                                                                               (fontSize: .medium, point: 11),
                                                                               (fontSize: .small,  point: 10)]
        mapFontTextStyleAndFontSizeAndPoint(fontSizeTuples: inputTextFontSizeTuples, mapping: &mapping, fontTextStyle: .inputText, contentSizeCategory: contentSizeCategory)

        /// fontTextStyle: none

        mapping[FontSpec(.large, .none, .none)]      = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.large, .medium, .none)]    = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.large, .semibold, .none)]  = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.large, .regular, .none)]   = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.large, .light, .none)]     = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.large, .thin, .none)]      = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .thin)

        mapping[FontSpec(.normal, .none, .none)]     = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.normal, .light, .none)]    = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.normal, .thin, .none)]     = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .thin)
        mapping[FontSpec(.normal, .regular, .none)]  = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.normal, .semibold, .none)] = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.normal, .medium, .none)]   = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.normal, .bold, .none)]   = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .bold)

        mapping[FontSpec(.medium, .none, .none)]     = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.medium, .bold, .none)]   = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .bold)
        mapping[FontSpec(.medium, .medium, .none)]   = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.medium, .semibold, .none)] = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.medium, .regular, .none)]  = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .regular)

        mapping[FontSpec(.small, .none, .none)]      = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.small, .bold, .none)]    = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .bold)
        mapping[FontSpec(.small, .medium, .none)]    = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.small, .semibold, .none)]  = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.small, .regular, .none)]   = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.small, .light, .none)]     = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)

        return mapping
    }
    
    convenience init(contentSizeCategory: UIContentSizeCategory) {
        self.init(fontMapping: type(of: self).defaultFontMapping(with: contentSizeCategory))
    }
    
    public init(fontMapping: FontMapping) {
        self.fontMapping = fontMapping
    }
    
    public func font(for fontType: FontSpec) -> UIFont? {
        return self.fontMapping[fontType]
    }
}
