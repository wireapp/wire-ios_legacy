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
    public func mix(_ color: UIColor, amount progress: CGFloat) -> UIColor {
        
        let component0 = components
        let component1 = color.components

        let red = mix(value0: component0.red, value1: component1.red, progress: progress)
        let green = mix(value0: component0.green, value1: component1.green, progress: progress)
        let blue = mix(value0: component0.blue, value1: component1.blue, progress: progress)
        let alpha = mix(value0: component0.alpha, value1: component1.alpha, progress: progress)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public func removeAlphaByBlending(with color: UIColor) -> UIColor {
        let component0 = components
        let component1 = color.components
        let alpha0 = component0.alpha
        
        let red = mix(value0: component1.red, value1: component0.red, progress: alpha0)
        let green = mix(value0: component1.green, value1: component0.green, progress: alpha0)
        let blue = mix(value0: component1.blue, value1: component0.blue, progress: alpha0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}
