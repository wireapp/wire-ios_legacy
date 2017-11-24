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

extension UIColor {
    static let background = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.0)
    static let inactiveButton = UIColor(red:0.20, green:0.22, blue:0.23, alpha:0.16)
    static let activeButton = UIColor(red:0.14, green:0.57, blue:0.83, alpha:1.0)
    static let createAccountBlue = UIColor(for: .strongBlue)!
    static let createTeamGreen = UIColor(for: .strongLimeGreen)!
    /// entered text/headline, entered text #33373A
    static let textColor = UIColor(red:0.20, green:0.22, blue:0.23, alpha:1.0)
    static let subtitleColor = UIColor(red:0.20, green:0.22, blue:0.23, alpha:0.56)
    static let activeButtonColor    = UIColor(rgb: 0x2391D3)
    static let errorMessageColor    = UIColor(rgb: 0xFB0807)
    static let inactiveButtonColor  = UIColor(rgb: 0x33373A, alpha:0.16)
    static let textfieldColor       = UIColor.white
    static let placeholderColor     = UIColor(rgb: 0x8D989F)



    /// Init a UIColor with RGB 24-bit value and alpha value
    ///
    /// - Parameters:
    ///   - rgb: a unsigned integer value form 0x000000 to 0xFFFFFF, e.g. 0x112233
    ///   - alpha: alpha value form 0 to 1
    public convenience init(rgb: UInt, alpha: CGFloat = 1.0) {
        let r, g, b: CGFloat
        r = CGFloat(rgb >> 16 & 0xFF) / 255.0
        g = CGFloat(rgb >> 8 & 0xFF) / 255.0
        b = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
