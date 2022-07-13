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

import UIKit
import WireSystem

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

    init(edgeInsets: UIEdgeInsets) {
        top = edgeInsets.top
        leading = edgeInsets.leading
        bottom = edgeInsets.bottom
        trailing = edgeInsets.trailing
    }
}

enum Anchor {
    case top
    case bottom
    case leading
    case trailing
}

enum AxisAnchor {
    case centerX
    case centerY
}

enum LengthAnchor {
    case width
    case height
}

struct LengthConstraints {
    let constraints: [LengthAnchor: NSLayoutConstraint]

    subscript(anchor: LengthAnchor) -> NSLayoutConstraint? {
        return constraints[anchor]
    }

    var array: [NSLayoutConstraint] {
        return constraints.values.map { $0 }
    }
}

extension UIView {

    /// fit self in a container view
    /// - Parameters:
    ///   - view: the container view to fit in
    ///   - inset: inset of self
    func fitIn(view: UIView, inset: CGFloat) {
        fitIn(view: view, insets: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
    }

    /// fit self in a container view
    /// notice bottom and right inset no need to set to negative of top/left, e.g. if you want to add inset to self with 2 pt:
    ///
    /// self.fitIn(view: container, insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))
    ///
    /// - Parameters:
    ///   - view: the container view to fit in
    ///   - insets: a UIEdgeInsets for inset of self.
    func fitIn(view: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate(fitInConstraints(view: view, insets: insets))
    }

    func fitInConstraints(view: UIView, inset: CGFloat) -> [NSLayoutConstraint] {
        return fitInConstraints(view: view, insets: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
    }

    func fitInConstraints(view: UIView,
                          insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        return [
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.trailing),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ]
    }
}
