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

public enum FontTextStyle: String {
    case largeTitle  = "largeTitle"
    case inputText   = "inputText"
}

public enum FontSize: String {
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
    static let weightMapping: [FontWeight: CGFloat] = [
        .ultraLight: UIFontWeightUltraLight,
        .thin:       UIFontWeightThin,
        .light:      UIFontWeightLight,
        .regular:    UIFontWeightRegular,
        .medium:     UIFontWeightMedium,
        .semibold:   UIFontWeightSemibold,
        .bold:       UIFontWeightBold,
        .heavy:      UIFontWeightHeavy,
        .black:      UIFontWeightBlack
    ]
    
    public var fontWeight: CGFloat {
        get {
            return type(of: self).weightMapping[self]!
        }
    }
    
    public init(weight: CGFloat) {
        self = (type(of: self).weightMapping.filter {
            $0.value == weight
            }.first?.key) ?? FontWeight.regular
    }
}

extension UIFont {
    static func systemFont(ofSize size: CGFloat, contentSizeCategory: UIContentSizeCategory, weight: FontWeight) -> UIFont {
        if #available(iOSApplicationExtension 8.2, *) {
            return self.systemFont(ofSize: round(size * UIFont.wr_preferredContentSizeMultiplier(for: contentSizeCategory)), weight: weight.fontWeight)
        } else {
            return self.systemFont(ofSize: round(size * UIFont.wr_preferredContentSizeMultiplier(for: contentSizeCategory)))
        }
    }
    
    public var classySystemFontName: String {
        get {
            let weightSpecifier = { () -> String in 
                guard #available(iOSApplicationExtension 8.2, *),
                    let traits = self.fontDescriptor.object(forKey: UIFontDescriptorTraitsAttribute) as? NSDictionary,
                    let floatWeight = traits[UIFontWeightTrait] as? NSNumber else {
                        return ""
                }
                
                return "-\(FontWeight(weight: CGFloat(floatWeight.floatValue)).rawValue.capitalized)"
            }()
            
            return "System\(weightSpecifier) \(self.pointSize)"
        }
    }
}

extension UIFont {
    public var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    
    public func italicFont() -> UIFont {
        
        if isItalic {
            return self
        } else {
            var symbolicTraits = fontDescriptor.symbolicTraits
            symbolicTraits.insert([.traitItalic])
            
            if let newFontDescriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) {
                return UIFont(descriptor: newFontDescriptor, size: pointSize)
            } else {
                return self
            }
        }
    }
}

public struct FontSpec {
    public let size: FontSize
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
}

extension FontSpec: Hashable {
    public var hashValue: Int {
        get {
            return self.size.hashValue * 1000 + (self.weight?.hashValue ?? 100)
        }
    }
}

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

@objc public final class FontScheme: NSObject {
    public typealias FontMapping = [FontSpec: UIFont]
    
    public var fontMapping: FontMapping = [:]
    
    fileprivate static func mapFontTextStyleAndFontSizeAndPoint(fintSizeTuples allFontSizes: [(fontSize: FontSize, point: CGFloat)], mapping: inout [FontSpec : UIFont], fontTextStyle: FontTextStyle, contentSizeCategory: UIContentSizeCategory) {
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
        mapFontTextStyleAndFontSizeAndPoint(fintSizeTuples: largeTitleFontSizeTuples, mapping: &mapping, fontTextStyle: .largeTitle, contentSizeCategory: contentSizeCategory)


        let inputTextFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large,  point: 21),
                                                                               (fontSize: .normal, point: 14),
                                                                               (fontSize: .medium, point: 11),
                                                                               (fontSize: .small,  point: 10)]
        mapFontTextStyleAndFontSizeAndPoint(fintSizeTuples: inputTextFontSizeTuples, mapping: &mapping, fontTextStyle: .inputText, contentSizeCategory: contentSizeCategory)

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

        mapping[FontSpec(.medium, .none, .none)]     = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.medium, .medium, .none)]   = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.medium, .semibold, .none)] = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.medium, .regular, .none)]  = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .regular)

        mapping[FontSpec(.small, .none, .none)]      = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.small, .medium, .none)]    = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.small, .semibold, .none)]  = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.small, .regular, .none)]   = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.small, .light, .none)]     = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)

        return mapping
    }
    
    public convenience init(contentSizeCategory: UIContentSizeCategory) {
        self.init(fontMapping: type(of: self).defaultFontMapping(with: contentSizeCategory))
    }
    
    public init(fontMapping: FontMapping) {
        self.fontMapping = fontMapping

        super.init()
    }
    
    public func font(for fontType: FontSpec) -> UIFont? {
        return self.fontMapping[fontType]
    }
}
