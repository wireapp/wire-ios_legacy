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

import Foundation

extension UIColor {

    fileprivate func mix(value0: CGFloat, value1: CGFloat, progress: CGFloat) -> CGFloat {
        return value0 * (1 - progress) + value1 * progress
    }

    /// Pass in amount of 0 for self, 1 is the other color
    ///
    /// - Parameters:
    ///   - color: other color to mix
    ///   - progress: amount of other color
    /// - Returns: the mixed color
    @objc
    func mix(_ color: UIColor, amount progress: CGFloat) -> UIColor {
        var red0: CGFloat = 0
        var green0: CGFloat = 0
        var blue0: CGFloat = 0
        var alpha0: CGFloat = 0
        var red1: CGFloat = 0
        var green1: CGFloat = 0
        var blue1: CGFloat = 0
        var alpha1: CGFloat = 0
        getRed(&red0, green: &green0, blue: &blue0, alpha: &alpha0)
        color.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        let red = mix(value0: red0, value1: red1, progress: progress)
        let green = mix(value0: green0, value1: green1, progress: progress)
        let blue = mix(value0: blue0, value1: blue1, progress: progress)
        let alpha = mix(value0: alpha0, value1: alpha1, progress: progress)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func removeAlphaByBlending(with color: UIColor) -> UIColor {
        var red0: CGFloat = 0
        var green0: CGFloat = 0
        var blue0: CGFloat = 0
        var alpha0: CGFloat = 0
        getRed(&red0, green: &green0, blue: &blue0, alpha: &alpha0)
        
        var red1: CGFloat = 0
        var green1: CGFloat = 0
        var blue1: CGFloat = 0
        color.getRed(&red1, green: &green1, blue: &blue1, alpha: nil)
        
        let red = mix(value0: red1, value1: red0, progress: alpha0)
        let green = mix(value0: green1, value1: green0, progress: alpha0)
        let blue = mix(value0: blue1, value1: blue0, progress: alpha0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    class func wr_color(from string: String) -> UIColor {
        let scanner = Scanner(string: string)
        
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "rgba(), ")
        
        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        var a: Float = 1
        scanner.scanFloat(&r)
        scanner.scanFloat(&g)
        scanner.scanFloat(&b)
        scanner.scanFloat(&a)
        
        if scanner.isAtEnd {
            return UIColor(red: CGFloat(r / 255), green: CGFloat(g / 255), blue: CGFloat(b / 255), alpha: CGFloat(a))
        } else {
            fatal("invalid color string")
        }
    }

}
