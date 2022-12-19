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
import WireCommonComponents

final class FontSchemeTests: XCTestCase {

    fileprivate func insertFontSizeItems(_ points: [FontSize: CGFloat], _ multiplier: CGFloat, _ fixedFontNames: inout [FontSpec: String], _ fontTextStyle: FontTextStyle) {
        let allFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large, point: round(points[FontSize.large]! * multiplier)),
                                                                         (fontSize: .normal, point: round(points[FontSize.normal]! * multiplier)),
                                                                         (fontSize: .medium, point: round(points[FontSize.medium]! * multiplier)),
                                                                         (fontSize: .small, point: round(points[FontSize.small]! * multiplier))]

        let allFontWeightTuples: [(fontWeight: FontWeight?, name: String)] = [(fontWeight: .ultraLight, name: "Ultralight"),
                                                                              (fontWeight: .thin, name: "Thin"),
                                                                              (fontWeight: .light, name: "Light"),
                                                                              (fontWeight: .regular, name: "Regular"),
                                                                              (fontWeight: .medium, name: "Medium"),
                                                                              (fontWeight: .semibold, name: "Semibold"),
                                                                              (fontWeight: .bold, name: "Bold"),
                                                                              (fontWeight: .heavy, name: "Heavy"),
                                                                              (fontWeight: .black, name: "Black"),
                                                                              (fontWeight: .none, name: "Light")
                                                                              ]

        for fontWeightTuple in allFontWeightTuples {
            for fontSizeTuple in allFontSizeTuples {
                fixedFontNames[FontSpec(fontSizeTuple.fontSize, fontWeightTuple.fontWeight, fontTextStyle)] = "System-\(fontWeightTuple.name) \(fontSizeTuple.point)"
            }
        }
    }

    fileprivate func insertInputTextFontSizeItems(multiplier: CGFloat, fixedFontNames: inout [FontSpec: String]) {
        let fontTextStyle: FontTextStyle = .inputText
        let points: [FontSize: CGFloat] = [FontSize.large: 21,
                                            FontSize.normal: 14,
                                            FontSize.medium: 11,
                                            FontSize.small: 10]

        insertFontSizeItems(points, multiplier, &fixedFontNames, fontTextStyle)
    }

    fileprivate func insertLargeTitleFontSizeItems(multiplier: CGFloat, fixedFontNames: inout [FontSpec: String]) {
        let fontTextStyle: FontTextStyle = .largeTitle
        let points: [FontSize: CGFloat] = [FontSize.large: 40,
                                            FontSize.normal: 26,
                                            FontSize.medium: 20,
                                            FontSize.small: 18]

        insertFontSizeItems(points, multiplier, &fixedFontNames, fontTextStyle)
    }

    func testThatItReturnsRegularWeightForLightFontsWhenAccessibilityBoldTextEnabled() {
        // GIVEN
        XCTAssertEqual(UIFont.Weight.ultraLight, FontWeight.ultraLight.fontWeight(accessibilityBoldText: false))
        XCTAssertEqual(UIFont.Weight.thin, FontWeight.thin.fontWeight(accessibilityBoldText: false))
        XCTAssertEqual(UIFont.Weight.light, FontWeight.light.fontWeight(accessibilityBoldText: false))

        // THEN
        XCTAssertEqual(UIFont.Weight.regular, FontWeight.ultraLight.fontWeight(accessibilityBoldText: true))
        XCTAssertEqual(UIFont.Weight.regular, FontWeight.thin.fontWeight(accessibilityBoldText: true))
        XCTAssertEqual(UIFont.Weight.regular, FontWeight.light.fontWeight(accessibilityBoldText: true))
    }
}
