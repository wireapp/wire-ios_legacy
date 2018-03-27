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

extension UIView {
    @discardableResult func fitInSuperview(with insets: EdgeInsets = .zero) -> [NSLayoutConstraint] {
        guard let superview = self.superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }
        
        let constraints = [
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.leading),
            self.topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.trailing)
        ]
        NSLayoutConstraint.activate(constraints)
        
        return constraints
    }
}
