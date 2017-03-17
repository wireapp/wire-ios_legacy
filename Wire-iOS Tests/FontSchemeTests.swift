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
import XCTest
@testable import Wire
@testable import WireExtensionComponents


class FontSchemeTests: XCTestCase {
   
    func testThatItConvertsFontToClassyName() {
        var fixedFontNames: [FontSpec: String] = [:]
        
        fixedFontNames[FontSpec(.large, .none)]       = "System-Light 24.0"
        fixedFontNames[FontSpec(.large, .medium)]     = "System-Medium 24.0"
        fixedFontNames[FontSpec(.large, .semibold)]   = "System-Semibold 24.0"
        fixedFontNames[FontSpec(.large, .light)]      = "System-Light 24.0"
        fixedFontNames[FontSpec(.large, .thin)]       = "System-Thin 24.0"
        
        fixedFontNames[FontSpec(.normal, .none)]      = "System-Light 16.0"
        fixedFontNames[FontSpec(.normal, .light)]     = "System-Light 16.0"
        fixedFontNames[FontSpec(.normal, .thin)]      = "System-Thin 16.0"
        fixedFontNames[FontSpec(.normal, .medium)]    = "System-Medium 16.0"
        fixedFontNames[FontSpec(.normal, .semibold)]  = "System-Semibold 16.0"
        
        fixedFontNames[FontSpec(.medium, .none)]      = "System-Light 12.0"
        fixedFontNames[FontSpec(.medium, .medium)]    = "System-Medium 12.0"
        fixedFontNames[FontSpec(.medium, .semibold)]  = "System-Semibold 12.0"
        fixedFontNames[FontSpec(.medium, .regular)]   = "System-Regular 12.0"
        
        fixedFontNames[FontSpec(.small, .none)]       = "System-Light 11.0"
        fixedFontNames[FontSpec(.small, .medium)]     = "System-Medium 11.0"
        fixedFontNames[FontSpec(.small, .semibold)]   = "System-Semibold 11.0"
        fixedFontNames[FontSpec(.small, .light)]      = "System-Light 11.0"
        
        // WHEN
        var fontNames: [FontSpec: String] = [:]
            
        FontScheme(contentSizeCategory: UIContentSizeCategory.large).fontMapping.forEach {
            fontNames[$0.key] = $0.value.classySystemFontName
        }
        
        // THEN
        
        XCTAssertEqual(fontNames, fixedFontNames)
    }

    
    func testThatItConvertsFontToClassyNameIfFontAdjustedExtraExtraExtraLarge() {
        var fixedFontNames: [FontSpec: String] = [:]
        
        fixedFontNames[FontSpec(.large, .none)]      = "System-Light 33.0"
        fixedFontNames[FontSpec(.large, .medium)]    = "System-Medium 33.0"
        fixedFontNames[FontSpec(.large, .semibold)]  = "System-Semibold 33.0"
        fixedFontNames[FontSpec(.large, .light)]     = "System-Light 33.0"
        fixedFontNames[FontSpec(.large, .thin)]      = "System-Thin 33.0"
        
        fixedFontNames[FontSpec(.normal, .none)]     = "System-Light 22.0"
        fixedFontNames[FontSpec(.normal, .light)]    = "System-Light 22.0"
        fixedFontNames[FontSpec(.normal, .thin)]     = "System-Thin 22.0"
        fixedFontNames[FontSpec(.normal, .medium)]   = "System-Medium 22.0"
        fixedFontNames[FontSpec(.normal, .semibold)] = "System-Semibold 22.0"

        fixedFontNames[FontSpec(.medium, .none)]     = "System-Light 17.0"
        fixedFontNames[FontSpec(.medium, .medium)]   = "System-Medium 17.0"
        fixedFontNames[FontSpec(.medium, .semibold)] = "System-Semibold 17.0"
        fixedFontNames[FontSpec(.medium, .regular)]  = "System-Regular 17.0"
        
        fixedFontNames[FontSpec(.small, .none)]      = "System-Light 15.0"
        fixedFontNames[FontSpec(.small, .medium)]    = "System-Medium 15.0"
        fixedFontNames[FontSpec(.small, .semibold)]  = "System-Semibold 15.0"
        fixedFontNames[FontSpec(.small, .light)]     = "System-Light 15.0"
        
        // WHEN
        var fontNames: [FontSpec: String] = [:]
        
        FontScheme(contentSizeCategory: UIContentSizeCategory.extraExtraExtraLarge).fontMapping.forEach {
            fontNames[$0.key] = $0.value.classySystemFontName
        }
        
        // THEN
        
        XCTAssertEqual(fontNames, fixedFontNames)
    }

    
    func testThatItConvertsFontToClassyNameIfFontAdjustedExtraSmall() {
        var fixedFontNames: [FontSpec: String] = [:]
        
        fixedFontNames[FontSpec(.large, .none)]       = "System-Light 20.0"
        fixedFontNames[FontSpec(.large, .medium)]     = "System-Medium 20.0"
        fixedFontNames[FontSpec(.large, .semibold)]   = "System-Semibold 20.0"
        fixedFontNames[FontSpec(.large, .light)]      = "System-Light 20.0"
        fixedFontNames[FontSpec(.large, .thin)]       = "System-Thin 20.0"
        
        fixedFontNames[FontSpec(.normal, .none)]      = "System-Light 13.0"
        fixedFontNames[FontSpec(.normal, .light)]     = "System-Light 13.0"
        fixedFontNames[FontSpec(.normal, .thin)]      = "System-Thin 13.0"
        fixedFontNames[FontSpec(.normal, .medium)]    = "System-Medium 13.0"
        fixedFontNames[FontSpec(.normal, .semibold)]  = "System-Semibold 13.0"
        
        fixedFontNames[FontSpec(.medium, .none)]      = "System-Light 10.0"
        fixedFontNames[FontSpec(.medium, .medium)]    = "System-Medium 10.0"
        fixedFontNames[FontSpec(.medium, .semibold)]  = "System-Semibold 10.0"
        fixedFontNames[FontSpec(.medium, .regular)]   = "System-Regular 10.0"
        
        fixedFontNames[FontSpec(.small, .none)]       = "System-Light 9.0"
        fixedFontNames[FontSpec(.small, .medium)]     = "System-Medium 9.0"
        fixedFontNames[FontSpec(.small, .semibold)]   = "System-Semibold 9.0"
        fixedFontNames[FontSpec(.small, .light)]      = "System-Light 9.0"
        
        // WHEN
        var fontNames: [FontSpec: String] = [:]
        
        FontScheme(contentSizeCategory: UIContentSizeCategory.extraSmall).fontMapping.forEach {
            fontNames[$0.key] = $0.value.classySystemFontName
        }
        
        // THEN
        
        XCTAssertEqual(fontNames, fixedFontNames)
    }

}
