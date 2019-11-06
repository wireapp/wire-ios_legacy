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
        
        let component0 = components
        let component1 = color.components

        let red = mix(value0: component0.r, value1: component1.r, progress: progress)
        let green = mix(value0: component0.g, value1: component1.g, progress: progress)
        let blue = mix(value0: component0.b, value1: component1.b, progress: progress)
        let alpha = mix(value0: component0.a, value1: component1.a, progress: progress)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }///TODO: test
    
    func removeAlphaByBlending(with color: UIColor) -> UIColor {
        let component0 = components
        let component1 = color.components
        let alpha0 = component0.a
        
        let red = mix(value0: component0.r, value1: component1.r, progress: alpha0)
        let green = mix(value0: component0.g, value1: component1.g, progress: alpha0)
        let blue = mix(value0: component0.b, value1: component1.b, progress: alpha0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }///TODO: test
    
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
