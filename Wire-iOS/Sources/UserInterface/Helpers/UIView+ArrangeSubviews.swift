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

typealias ViewWithInsets = (UIView, UIEdgeInsets)

extension UIView {
    
    /// Arrange subviews vertically taking the insets for each view into account.
    ///
    /// - parameter views: views which in the order in which they should be layed out.
    /// - Returns: constraints created (already activated).
    @discardableResult
    func arrangeSubviews(_ views: [ViewWithInsets]) -> [NSLayoutConstraint] {
        
        var constraints: [NSLayoutConstraint] = []
        
        if let (firstView, insets) = views.first {
            constraints += [firstView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top)]
        }
        
        for (view, insets) in views {
            constraints += [
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
            ]
        }
        
        for ((view, viewInsets), (precedingView, precedingViewInsets)) in zip(views.dropFirst(), views.dropLast()) {
            constraints += [view.topAnchor.constraint(equalTo: precedingView.bottomAnchor, constant: max(viewInsets.top, precedingViewInsets.bottom))]
        }
        
        if let (lastView, insets) = views.last {
            constraints += [lastView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)]
        }
        
        NSLayoutConstraint.activate(constraints)
        
        return constraints
    }
    
}
