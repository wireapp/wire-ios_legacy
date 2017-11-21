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
    static let activeButtonColor = UIColor(hexString: "#2391D3")!
    static let errorMessageColor = UIColor(hexString: "#FB0807")!
    static let inactiveButtonColor = UIColor(hexString: "#33373A40")!
    static let textfieldColor = UIColor.white
    static let placeholderColor = UIColor(hexString: "#8D989F")!


    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat

        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
