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

struct EdgeInsets {
    let top, leading, bottom, trailing: CGFloat
    
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    
    init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
    
    init(margin: CGFloat) {
        self = EdgeInsets(top: margin, leading: margin, bottom: margin, trailing: margin)
    }
}

enum Anchor {
    case top
    case bottom
    case leading
    case trailing
}

extension UIView {
    @discardableResult func fitInSuperview(safely: Bool = false,
                                           with insets: EdgeInsets = .zero,
                                           exclude excludedAnchor: Anchor? = nil) -> [NSLayoutConstraint] {
        guard let superview = self.superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }

        var constraints: [NSLayoutConstraint] = []

        if excludedAnchor != .leading {
            constraints.append(leadingAnchor.constraint(
                equalTo: safely ? superview.safeLeadingAnchor : superview.leadingAnchor,
                constant: insets.leading))
        }

        if excludedAnchor != .bottom {
            constraints.append(bottomAnchor.constraint(
                equalTo: safely ? superview.safeBottomAnchor : superview.bottomAnchor,
                constant: -insets.bottom))
        }

        if excludedAnchor != .top {
            constraints.append(topAnchor.constraint(
                equalTo: safely ? superview.safeTopAnchor : superview.topAnchor,
                constant: insets.top))
        }

        if excludedAnchor != .trailing {
            constraints.append(trailingAnchor.constraint(
                equalTo: safely ? superview.safeTrailingAnchor : superview.trailingAnchor,
                constant: -insets.trailing))
        }

        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
