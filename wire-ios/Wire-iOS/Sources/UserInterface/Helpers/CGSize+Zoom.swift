//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import UIKit

extension CGSize {
    func minZoom(imageSize: CGSize?) -> CGFloat {
        guard let imageSize = imageSize else { return 1 }
        guard imageSize != .zero else { return 1 }
        guard self != .zero else { return 1 }

        var minZoom = min(self.width / imageSize.width, self.height / imageSize.height)

        if minZoom > 1 {
            minZoom = 1
        }

        return minZoom
    }

    /// returns true if both with and height are longer than otherSize
    ///
    /// - Parameter otherSize: other CGSize to compare
    /// - Returns: true if both with and height are longer than otherSize
    func contains(_ otherSize: CGSize) -> Bool {
        return otherSize.width < width &&
               otherSize.height < height
    }
}
