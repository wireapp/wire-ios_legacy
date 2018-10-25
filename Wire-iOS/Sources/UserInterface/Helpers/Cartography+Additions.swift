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
import Cartography

extension Cartography.Point {
    func edge(with value: NSLayoutConstraint.Attribute) -> Cartography.Edge? {
        return self.properties.filter { $0.attribute == value }.first as? Edge
    }
    
    var centerX: Cartography.Edge {
        return self.edge(with: .centerX)!
    }
    
    var centerY: Cartography.Edge {
        return self.edge(with: .centerY)!
    }
    
    @discardableResult func layout(around: Cartography.Point, at angle: CGFloat, diameter: CGFloat) -> [NSLayoutConstraint] {
        let x = ceil(sin(angle) * diameter)
        let y = ceil(cos(angle) * diameter)
        return [self.centerX == around.centerX + x,
                self.centerY == around.centerY + y]
        
    }
    
}
