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
            }.first?.key)!
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

public struct FontSpec {
    public let size: FontSize
    public let weight: FontWeight?
    
    public init(_ size: FontSize, _ weight: FontWeight?) {
        self.size = size
        self.weight = weight
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
            if let weight = self.weight {
                return "\(self.size)-\(weight)"
            }
            else {
                return "\(self.size)"
            }
        }
    }
}

public func==(left: FontSpec, right: FontSpec) -> Bool {
    return left.size == right.size && left.weight == right.weight
}

@objc public final class FontScheme: NSObject {
    public typealias FontMapping = [FontSpec: UIFont]
    
    public var fontMapping: FontMapping = [:]
    
    public static func defaultFontMapping(with contentSizeCategory: UIContentSizeCategory) -> FontMapping {
        var mapping: FontMapping = [:]
        
        mapping[FontSpec(.large, .none)]     = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.large, .medium)]   = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.large, .light)]    = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.large, .thin)]     = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .thin)
        
        mapping[FontSpec(.normal, .none)]    = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.normal, .light)]   = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.normal, .thin)]    = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .thin)
        mapping[FontSpec(.normal, .medium)]  = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .medium)
        
        mapping[FontSpec(.medium, .none)]    = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.medium, .medium)]  = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.medium, .regular)] = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .regular)
        
        mapping[FontSpec(.small, .none)]     = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.small, .medium)]   = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.small, .light)]    = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)

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
