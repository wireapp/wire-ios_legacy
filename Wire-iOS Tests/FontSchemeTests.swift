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

    fileprivate func insertFontSizeItems(_ points: [FontSize : CGFloat], _ multiplier: CGFloat, _ fixedFontNames: inout [FontSpec : String], _ fontTextStyle: FontTextStyle) {
        let allFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large,  point: round(points[FontSize.large]! * multiplier)),
                                                                         (fontSize: .normal, point: round(points[FontSize.normal]! * multiplier)),
                                                                         (fontSize: .medium, point: round(points[FontSize.medium]! * multiplier)),
                                                                         (fontSize: .small,  point: round(points[FontSize.small]! * multiplier))]

        let allFontWeightTuples: [(fontWeight: FontWeight?, name: String)] = [(fontWeight: .ultraLight, name: "Ultralight"),
                                                                              (fontWeight: .thin, name: "Thin"),
                                                                              (fontWeight: .light, name: "Light"),
                                                                              (fontWeight: .regular, name: "Regular"),
                                                                              (fontWeight: .medium, name: "Medium"),
                                                                              (fontWeight: .semibold, name: "Semibold"),
                                                                              (fontWeight: .bold, name: "Bold"),
                                                                              (fontWeight: .heavy, name: "Heavy"),
                                                                              (fontWeight: .black, name: "Black"),
                                                                              (fontWeight: .none, name: "Light"),
                                                                              ]


        for fontWeightTuple in allFontWeightTuples {
            for fontSizeTuple in allFontSizeTuples {
                fixedFontNames[FontSpec(fontSizeTuple.fontSize, fontWeightTuple.fontWeight, fontTextStyle)] = "System-\(fontWeightTuple.name) \(fontSizeTuple.point)"
            }
        }
    }

    fileprivate func insertInputTextFontSizeItems(multiplier: CGFloat, fixedFontNames: inout [FontSpec : String]) {
        let fontTextStyle: FontTextStyle = .inputText
        let points: [FontSize : CGFloat] = [FontSize.large: 21,
                                            FontSize.normal: 14,
                                            FontSize.medium: 11,
                                            FontSize.small: 10]

        insertFontSizeItems(points, multiplier, &fixedFontNames, fontTextStyle)
    }

    fileprivate func insertLargeTitleFontSizeItems(multiplier: CGFloat, fixedFontNames: inout [FontSpec : String]) {
        let fontTextStyle: FontTextStyle = .largeTitle
        let points: [FontSize : CGFloat] = [FontSize.large: 40,
                                            FontSize.normal: 26,
                                            FontSize.medium: 20,
                                            FontSize.small: 18]

        insertFontSizeItems(points, multiplier, &fixedFontNames, fontTextStyle)
    }

    func testThatItConvertsFontToClassyName() {
        var fixedFontNames: [FontSpec: String] = [:]

        /// insert item for fontTextStyle = none

        fixedFontNames[FontSpec(.large, .none)]       = "System-Light 24.0"
        fixedFontNames[FontSpec(.large, .medium)]     = "System-Medium 24.0"
        fixedFontNames[FontSpec(.large, .semibold)]   = "System-Semibold 24.0"
        fixedFontNames[FontSpec(.large, .regular)]    = "System-Regular 24.0"
        fixedFontNames[FontSpec(.large, .light)]      = "System-Light 24.0"
        fixedFontNames[FontSpec(.large, .thin)]       = "System-Thin 24.0"
        
        fixedFontNames[FontSpec(.normal, .none)]      = "System-Light 16.0"
        fixedFontNames[FontSpec(.normal, .light)]     = "System-Light 16.0"
        fixedFontNames[FontSpec(.normal, .thin)]      = "System-Thin 16.0"
        fixedFontNames[FontSpec(.normal, .regular)]   = "System-Regular 16.0"
        fixedFontNames[FontSpec(.normal, .medium)]    = "System-Medium 16.0"
        fixedFontNames[FontSpec(.normal, .semibold)]  = "System-Semibold 16.0"
        
        fixedFontNames[FontSpec(.medium, .none)]      = "System-Light 12.0"
        fixedFontNames[FontSpec(.medium, .medium)]    = "System-Medium 12.0"
        fixedFontNames[FontSpec(.medium, .semibold)]  = "System-Semibold 12.0"
        fixedFontNames[FontSpec(.medium, .regular)]   = "System-Regular 12.0"
        
        fixedFontNames[FontSpec(.small, .none)]       = "System-Light 11.0"
        fixedFontNames[FontSpec(.small, .medium)]     = "System-Medium 11.0"
        fixedFontNames[FontSpec(.small, .semibold)]   = "System-Semibold 11.0"
        fixedFontNames[FontSpec(.small, .regular)]    = "System-Regular 11.0"
        fixedFontNames[FontSpec(.small, .light)]      = "System-Light 11.0"

        /// insert item for fontTextStyle = LargeTitle
        insertLargeTitleFontSizeItems(multiplier: 1, fixedFontNames: &fixedFontNames)
        insertInputTextFontSizeItems(multiplier: 1, fixedFontNames: &fixedFontNames)

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
        fixedFontNames[FontSpec(.large, .regular)]   = "System-Regular 33.0"
        fixedFontNames[FontSpec(.large, .light)]     = "System-Light 33.0"
        fixedFontNames[FontSpec(.large, .thin)]      = "System-Thin 33.0"
        
        fixedFontNames[FontSpec(.normal, .none)]     = "System-Light 22.0"
        fixedFontNames[FontSpec(.normal, .light)]    = "System-Light 22.0"
        fixedFontNames[FontSpec(.normal, .thin)]     = "System-Thin 22.0"
        fixedFontNames[FontSpec(.normal, .regular)]  = "System-Regular 22.0"
        fixedFontNames[FontSpec(.normal, .medium)]   = "System-Medium 22.0"
        fixedFontNames[FontSpec(.normal, .semibold)] = "System-Semibold 22.0"

        fixedFontNames[FontSpec(.medium, .none)]     = "System-Light 17.0"
        fixedFontNames[FontSpec(.medium, .medium)]   = "System-Medium 17.0"
        fixedFontNames[FontSpec(.medium, .semibold)] = "System-Semibold 17.0"
        fixedFontNames[FontSpec(.medium, .regular)]  = "System-Regular 17.0"
        
        fixedFontNames[FontSpec(.small, .none)]      = "System-Light 15.0"
        fixedFontNames[FontSpec(.small, .medium)]    = "System-Medium 15.0"
        fixedFontNames[FontSpec(.small, .semibold)]  = "System-Semibold 15.0"
        fixedFontNames[FontSpec(.small, .regular)]   = "System-Regular 15.0"
        fixedFontNames[FontSpec(.small, .light)]     = "System-Light 15.0"

        let multipler : CGFloat = 22.0 / 16.0
        insertLargeTitleFontSizeItems(multiplier: multipler, fixedFontNames: &fixedFontNames)
        insertInputTextFontSizeItems(multiplier: multipler, fixedFontNames: &fixedFontNames)

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
        fixedFontNames[FontSpec(.large, .regular)]    = "System-Regular 20.0"
        fixedFontNames[FontSpec(.large, .light)]      = "System-Light 20.0"
        fixedFontNames[FontSpec(.large, .thin)]       = "System-Thin 20.0"
        
        fixedFontNames[FontSpec(.normal, .none)]      = "System-Light 13.0"
        fixedFontNames[FontSpec(.normal, .light)]     = "System-Light 13.0"
        fixedFontNames[FontSpec(.normal, .thin)]      = "System-Thin 13.0"
        fixedFontNames[FontSpec(.normal, .regular)]   = "System-Regular 13.0"
        fixedFontNames[FontSpec(.normal, .medium)]    = "System-Medium 13.0"
        fixedFontNames[FontSpec(.normal, .semibold)]  = "System-Semibold 13.0"
        
        fixedFontNames[FontSpec(.medium, .none)]      = "System-Light 10.0"
        fixedFontNames[FontSpec(.medium, .medium)]    = "System-Medium 10.0"
        fixedFontNames[FontSpec(.medium, .semibold)]  = "System-Semibold 10.0"
        fixedFontNames[FontSpec(.medium, .regular)]   = "System-Regular 10.0"
        
        fixedFontNames[FontSpec(.small, .none)]       = "System-Light 9.0"
        fixedFontNames[FontSpec(.small, .medium)]     = "System-Medium 9.0"
        fixedFontNames[FontSpec(.small, .semibold)]   = "System-Semibold 9.0"
        fixedFontNames[FontSpec(.small, .regular)]    = "System-Regular 9.0"
        fixedFontNames[FontSpec(.small, .light)]      = "System-Light 9.0"

        let multipler : CGFloat = 13.0 / 16.0
        insertLargeTitleFontSizeItems(multiplier: multipler, fixedFontNames: &fixedFontNames)
        insertInputTextFontSizeItems(multiplier: multipler, fixedFontNames: &fixedFontNames)

        // WHEN
        var fontNames: [FontSpec: String] = [:]
        
        FontScheme(contentSizeCategory: UIContentSizeCategory.extraSmall).fontMapping.forEach {
            fontNames[$0.key] = $0.value.classySystemFontName
        }
        
        // THEN
        XCTAssertEqual(fontNames, fixedFontNames)
    }

}
