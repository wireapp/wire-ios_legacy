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

private let allCapsGeatureSettingsAttributeLowerCase = [
    UIFontFeatureTypeIdentifierKey: kLowerCaseType,
    UIFontFeatureSelectorIdentifierKey: kLowerCaseSmallCapsSelector,
]

private let allCapsGeatureSettingsAttributeUpperCase = [
    UIFontFeatureTypeIdentifierKey: kUpperCaseType,
    UIFontFeatureSelectorIdentifierKey: kUpperCaseSmallCapsSelector,
]

private let allCapsAttribute = [
    UIFontDescriptorFeatureSettingsAttribute: [allCapsGeatureSettingsAttributeLowerCase, allCapsGeatureSettingsAttributeUpperCase]
]

extension UIFont {
    
    func monospacedFont() -> UIFont {
        let descriptor = fontDescriptor()
        let monospaceFontDescriptor = descriptor.fontDescriptorByAddingAttributes(monospaceAttribute)
        return UIFont(descriptor: monospaceFontDescriptor, size: 0.0)
    }
    
    func allCaps() -> UIFont {
        let descriptor = fontDescriptor()
        let allCapsDescriptor = descriptor.fontDescriptorByAddingAttributes(allCapsAttribute)
        return UIFont(descriptor: allCapsDescriptor, size: 0.0)
    }
    
}
