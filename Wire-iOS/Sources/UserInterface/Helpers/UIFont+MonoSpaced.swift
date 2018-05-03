// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

private let monospacedFeatureSettingsAttribute = [
    UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
    UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
]

private let monospaceAttribute = [
    UIFontDescriptorFeatureSettingsAttribute: [monospacedFeatureSettingsAttribute]
]

private let smallCapsFeatureSettingsAttributeLowerCase = [
    UIFontFeatureTypeIdentifierKey: kLowerCaseType,
    UIFontFeatureSelectorIdentifierKey: kLowerCaseSmallCapsSelector,
]

private let smallCapsFeatureSettingsAttributeUpperCase = [
    UIFontFeatureTypeIdentifierKey: kUpperCaseType,
    UIFontFeatureSelectorIdentifierKey: kUpperCaseSmallCapsSelector,
]

private let proportionalNumberSpacingFeatureSettingAttribute = [
    UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
    UIFontFeatureSelectorIdentifierKey: kProportionalNumbersSelector
]

private let smallCapsAttribute = [
    UIFontDescriptorFeatureSettingsAttribute: [smallCapsFeatureSettingsAttributeLowerCase, smallCapsFeatureSettingsAttributeUpperCase]
]

private let proportionalNumberSpacingAttribute = [
    UIFontDescriptorFeatureSettingsAttribute: [proportionalNumberSpacingFeatureSettingAttribute]
]

extension UIFont {
    
    func monospaced() -> UIFont {
        let descriptor = fontDescriptor
        let monospaceFontDescriptor = descriptor.addingAttributes(monospaceAttribute)
        return UIFont(descriptor: monospaceFontDescriptor, size: 0.0)
    }
    
    func smallCaps() -> UIFont {
        let descriptor = fontDescriptor
        let allCapsDescriptor = descriptor.addingAttributes(smallCapsAttribute)
        return UIFont(descriptor: allCapsDescriptor, size: 0.0)
    }
    
    func proportionalNumberSpacing() -> UIFont {
        let descriptor = fontDescriptor
        let propertionalNumberSpacingDescriptor = descriptor.addingAttributes(proportionalNumberSpacingAttribute)
        return UIFont(descriptor: propertionalNumberSpacingDescriptor, size: 0.0)
    }
    
}

extension FontSpec {
    var font: UIFont? {
        let fontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        return fontScheme.font(for: self)
    }
}
