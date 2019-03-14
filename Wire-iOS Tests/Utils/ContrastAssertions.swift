//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import XCTest
@testable import Wire

/**
 * The type of content that is displayed in the foreground.
 */

enum ForegroundContentType {
    case text(size: CGFloat, isBold: Bool)
    case contextProvidingImage

    /// The required contrast with the background to pass AAA compliance.
    var requiredAAAContrast: CGFloat {
        switch self {
        case .text(let size, let isBold):
            if isBold {
                return size >= 14 ? 4.5 : 7
            } else {
                return size >= 18 ? 4.5 : 7
            }
        case .contextProvidingImage:
            return 4.5
        }
    }

    /// The required contrast with the foreground to pass AA compliance.
    var requiredAAContrast: CGFloat {
        switch self {
        case .text(let size, let isBold):
            if isBold {
                return size >= 14 ? 3 : 4.5
            } else {
                return size >= 18 ? 3 : 4.5
            }
        case .contextProvidingImage:
            return 3/1
        }
    }
}

/**
 * A test assertion to validate that we pass required color contrast between two colors.
 * - parameter background: The background color to test.
 * - parameter foreground: The foreground color to test.
 * - parameter contentType: The type of content we are testing for.
 * - parameter variant: The color scheme variant in which the test is performed. Defaults to light.
 * - parameter tolerateAA: Whether we tolerate the AA-compliance level, or require AAA. Default to true.
 * - parameter file: The file where this assertion is made.
 * - parameter line: The line in the file where this assertion is made.
 */

func WRValidateContrast(background: UIColor?, foreground: UIColor?, contentType: ForegroundContentType, variant: ColorSchemeVariant = .light, tolerateAA: Bool = true, file: StaticString = #file, line: UInt = #line) {
    // If there is no background color, we assume the default one for the
    let background = background ?? UIColor.from(scheme: .background, variant: variant)

    // We require a foreground color, but the argument is optional
    // to match the signature of `-[UILabel textColor]` which is optional too.
    guard let foreground = foreground?.removeAlphaByBlending(with: background) else {
        return XCTFail("Missing foreground color.", file: file, line: line)
    }

    let backgroundLuminance = background.luminance
    let foregroundLuminance = foreground.luminance

    let l1 = max(backgroundLuminance, foregroundLuminance)
    let l2 = min(backgroundLuminance, foregroundLuminance)
    let contrast = (l1 + 0.05) / (l2 + 0.05)

    // Check for  compliance
    let aaaCompliant = contrast >= contentType.requiredAAAContrast
    let aaCompliant = contrast >= contentType.requiredAAContrast

    if !aaaCompliant && !tolerateAA {
        return XCTFail("Failed AAA contrast test: \(contrast.formattedForContrastDebugging):1", file: file, line: line)
    }

    if !aaCompliant {
        return XCTFail("Failed AA contrast test: \(contrast.formattedForContrastDebugging):1", file: file, line: line)
    }

    return
}

/**
 * Validates the contrast of a text label.
 * - parameter label: The label to test.
 * - parameter background: The background color to test.
 * - parameter variant: The color scheme variant in which the test is performed. Defaults to light.
 * - parameter tolerateAA: Whether we tolerate the AA-compliance level, or require AAA. Default to true.
 * - parameter file: The file where this assertion is made.
 * - parameter line: The line in the file where this assertion is made.
 */

func WRValidateLabelContrast(_ label: UILabel?, background: UIColor?, variant: ColorSchemeVariant = .light, tolerateAA: Bool = true, file: StaticString = #file, line: UInt = #line) {
    guard let font = label?.font else {
        return XCTFail("Cannot find the font of the label.", file: file, line: line)
    }

    WRValidateContrast(background: background, foreground: label?.textColor, contentType: .text(size: font.pointSize, isBold: font.isBold), variant: variant, tolerateAA: tolerateAA, file: file, line: line)
}

/**
 * Validates the contrast of a text button.
 * - parameter button: The button to test.
 * - parameter state: The state in which the button should be tested. Defaults to normal.
 * - parameter background: The background color to test.
 * - parameter variant: The color scheme variant in which the test is performed. Defaults to light.
 * - parameter tolerateAA: Whether we tolerate the AA-compliance level, or require AAA. Default to true.
 * - parameter file: The file where this assertion is made.
 * - parameter line: The line in the file where this assertion is made.
 */

func WRValidateTextButtonContrast(_ button: UIButton?, forState state: UIControl.State = .normal, background: UIColor?, variant: ColorSchemeVariant = .light, tolerateAA: Bool = true, file: StaticString = #file, line: UInt = #line) {
    guard let font = button?.titleLabel?.font else {
        return XCTFail("Cannot find the font of the button label.", file: file, line: line)
    }

    let foreground = button?.titleColor(for: state)

    WRValidateContrast(background: background, foreground: foreground, contentType: .text(size: font.pointSize, isBold: font.isBold), variant: variant, tolerateAA: tolerateAA, file: file, line: line)
}

/**
 * Validates the contrast of an icon button.
 * - parameter button: The button to test.
 * - parameter state: The state in which the button should be tested. Defaults to normal.
 * - parameter variant: The color scheme variant in which the test is performed. Defaults to light.
 * - parameter tolerateAA: Whether we tolerate the AA-compliance level, or require AAA. Default to true.
 * - parameter file: The file where this assertion is made.
 * - parameter line: The line in the file where this assertion is made.
 */

func WRValidateIconButtonContrast(_ button: IconButton?, forState state: UIControl.State = .normal, variant: ColorSchemeVariant = .light, tolerateAA: Bool = true, file: StaticString = #file, line: UInt = #line) {
    let foreground = button?.iconColor(for: state)
    let background = button?.backgroundImageColor(for: state)

    WRValidateContrast(background: background, foreground: foreground, contentType: .contextProvidingImage, variant: variant, tolerateAA: tolerateAA, file: file, line: line)
}

// MARK: - Helpers

extension UIColor {

    /// Returns the individual components of the color.
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

    // Source: https://www.w3.org/TR/WCAG20-TECHS/G17.html
    /// Returns the perceived brightness of the color.
    var luminance: CGFloat {
        let (r, g, b, _) = self.components

        // rgb coefficients
        let rc: CGFloat = 0.2126
        let gc: CGFloat = 0.7152
        let bc: CGFloat = 0.0722

        // low-gamma adjust coefficient
        let lowc: CGFloat = 1 / 12.92

        let R = r <= lowc ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let G = g <= lowc ? g / 12.92 : pow((g + 0.055) / 1.005, 2.4)
        let B = b <= lowc ? b / 12.92 : pow((b + 0.055) / 1.005, 2.4)

        return R * rc + G * gc + B * bc
    }

}

extension CGFloat {

    fileprivate var formattedForContrastDebugging: String {
        return String(format: "%.02f", self)
    }

}
