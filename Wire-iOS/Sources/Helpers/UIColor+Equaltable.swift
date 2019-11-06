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
    struct Components: Equatable {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        init(color: UIColor) {
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
    }
    
    var components: Components {
        return Components(color: self)
    }
    
    static func == (lhs: UIColor, rhs: UIColor) -> Bool {
        return lhs.components == rhs.components
    }
    
    convenience init(tuple: (red: UInt, green: UInt, blue: UInt, alpha: CGFloat)) {
        
        self.init(red: CGFloat(tuple.red / 255), green: CGFloat(tuple.green / 255), blue: CGFloat(tuple.blue / 255), alpha: CGFloat(tuple.alpha))
    }

    convenience init(tuple: (red: UInt, green: UInt, blue: UInt)) {
        self.init(tuple: (red: tuple.red, green: tuple.green, blue: tuple.blue, alpha: 1))///TODO: test
    }

}

