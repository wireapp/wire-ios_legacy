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

extension UIView {
    var layoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 10, *) {
            return self.traitCollection.layoutDirection == .leftToRight ? .leftToRight : .rightToLeft
        }
        else {
            return UIView.userInterfaceLayoutDirection(for: .unspecified)
        }
    }
    
    @discardableResult func fitInSuperview(with insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        guard let superview = self.superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }
        
        let (leadingInset, trailingInset) = self.layoutDirection == .leftToRight ?
                                                (insets.left, insets.right) :
                                                (insets.right, insets.left)
        
        let constraints = [
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: leadingInset),
            self.topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -trailingInset)
        ]
        NSLayoutConstraint.activate(constraints)
        
        return constraints
    }
}
