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

extension UIView {

    // MARK: - center alignment

    @discardableResult func centerInSuperview(activate: Bool = true) -> [NSLayoutConstraint] {
        guard let superview = superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }

        return alignCenter(to: superview, activate: activate)
    }

    @discardableResult func alignCenter(to view: UIView,
                                        with offset: CGPoint = .zero,
                                        activate: Bool = true) -> [NSLayoutConstraint] {

        let constraints = [
            view.centerXAnchor.constraint(equalTo: centerXAnchor, constant: offset.x),
            view.centerYAnchor.constraint(equalTo: centerYAnchor, constant: offset.y)
        ]

        if activate {
            NSLayoutConstraint.activate(constraints)
        }

        return constraints
    }

    @discardableResult func pinToSuperview(axisAnchor: AxisAnchor,
                                           constant: CGFloat = 0,
                                           activate: Bool = true) -> NSLayoutConstraint {
        guard let superview = superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }

        var selfAnchor: NSObject!
        var superAnchor: NSObject!

        switch axisAnchor {
        case .centerX:
            selfAnchor = centerXAnchor
            superAnchor = superview.centerXAnchor
        case .centerY:
            selfAnchor = centerYAnchor
            superAnchor = superview.centerYAnchor
        }

        let constraint = (selfAnchor as! NSLayoutAnchor<AnyObject>).constraint(equalTo: (superAnchor as! NSLayoutAnchor<AnyObject>), constant: constant)
        constraint.isActive = activate

        return constraint
    }

    // MARK: - signal edge alignment

    /// Pin this view's specific edge to superview's same edge with custom inset
    ///
    /// - Parameters:
    ///   - anchor: the edge to pin
    ///   - inset: the inset to the edge
    ///   - activate: true by default, set to false if do not activate the NSLayoutConstraint
    /// - Returns: the NSLayoutConstraint created
    @discardableResult func pinToSuperview(anchor: Anchor,
                                           inset: CGFloat = 0,
                                           activate: Bool = true) -> NSLayoutConstraint {
        guard let superview = superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }

        let constant: CGFloat
        switch anchor {
        case .top, .leading:
            constant = inset
        case .bottom, .trailing:
            constant = -inset
        }

        var selfAnchor: NSObject!
        var superAnchor: NSObject!

        switch anchor {
        case .top:
            selfAnchor = topAnchor
            superAnchor = superview.topAnchor
        case .bottom:
            selfAnchor = bottomAnchor
            superAnchor = superview.bottomAnchor
        case .leading:
            selfAnchor = leadingAnchor
            superAnchor = superview.leadingAnchor
        case .trailing:
            selfAnchor = trailingAnchor
            superAnchor = superview.trailingAnchor
        }

        let constraint = (selfAnchor as! NSLayoutAnchor<AnyObject>).constraint(equalTo: (superAnchor as! NSLayoutAnchor<AnyObject>), constant: constant)
        constraint.isActive = activate

        return constraint
    }

    // MARK: - all edges alignment

    @discardableResult func fitInSuperview(safely: Bool = false,
                                           with insets: EdgeInsets = .zero,
                                           exclude excludedAnchors: [Anchor] = [],
                                           activate: Bool = true) -> [Anchor: NSLayoutConstraint] {

        guard let superview = superview else {
            fatal("Not in view hierarchy: self.superview = nil")
        }

        return pin(to: superview,
                   safely: safely,
                   with: insets,
                   exclude: excludedAnchors,
                   activate: activate)
    }

    @discardableResult func pin(to view: UIView,
                                safely: Bool = false,
                                with insets: EdgeInsets = .zero,
                                exclude excludedAnchors: [Anchor] = [],
                                activate: Bool = true) -> [Anchor: NSLayoutConstraint] {

        var constraints: [Anchor: NSLayoutConstraint] = [:]

        if !excludedAnchors.contains(.leading) {
            let constraint = leadingAnchor.constraint(
                equalTo: safely ? view.safeLeadingAnchor : view.leadingAnchor,
                constant: insets.leading)

            constraints[.leading] = constraint
        }

        if !excludedAnchors.contains(.bottom) {
            let constraint = bottomAnchor.constraint(
                equalTo: safely ? view.safeBottomAnchor : view.bottomAnchor,
                constant: -insets.bottom)

            constraints[.bottom] = constraint
        }

        if !excludedAnchors.contains(.top) {
            let constraint = topAnchor.constraint(
                equalTo: safely ? view.safeTopAnchor : view.topAnchor,
                constant: insets.top)

            constraints[.top] = constraint
        }

        if !excludedAnchors.contains(.trailing) {
            let constraint = trailingAnchor.constraint(
                equalTo: safely ? view.safeTrailingAnchor : view.trailingAnchor,
                constant: -insets.trailing)

            constraints[.trailing] = constraint
        }

        if activate {
            NSLayoutConstraint.activate(constraints.map({$0.value}))
        }

        return constraints
    }

    // MARK: - dimensions

    func setDimensions(length: CGFloat) {
        setDimensions(width: length, height: length)
    }

    func setDimensions(width: CGFloat, height: CGFloat) {
        setDimensions(size: CGSize(width: width, height: height))
    }

    func setDimensions(size: CGSize) {
        let constraints = [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    @discardableResult func topAndBottomEdgesToSuperviewEdges() -> [NSLayoutConstraint] {
        guard let superview = superview else { return [] }

        return [
            superview.topAnchor.constraint(equalTo: topAnchor),
            superview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

}
