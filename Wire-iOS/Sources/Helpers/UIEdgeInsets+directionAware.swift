//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension UIView {
    var isLeftToRight: Bool {
        return effectiveUserInterfaceLayoutDirection == .leftToRight
    }
}

extension UIEdgeInsets {
    /// The leading insets, that respect the layout direction.
    func leading(view: UIView) -> CGFloat {
        if view.isLeftToRight {
            return left
        } else {
            return right
        }
    }

    /// The trailing insets, that respect the layout direction.
    func trailing(view: UIView) -> CGFloat {
        if view.isLeftToRight {
            return right
        } else {
            return left
        }
    }

    /// Returns a copy of the insets that are adapted for the current layout.
    func directionAwareInsets(view: UIView) -> UIEdgeInsets {
        return UIEdgeInsets(top: top,
                            left: leading(view: view),
                            bottom: bottom,
                            right: trailing(view: view))
    }
}
