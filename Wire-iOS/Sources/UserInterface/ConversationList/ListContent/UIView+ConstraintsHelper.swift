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

enum AnchorType {
    case top, bottom, leading, trailing
}

extension UIView {
    func setDimensions(length: CGFloat) {
        setDimensions(width: length, height: length)
    }

    func setDimensions(width: CGFloat, height: CGFloat) {
        let constraints = [
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: height)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func topAndBottomEdgesToSuperviewEdges() -> [NSLayoutConstraint] {
        guard let superview = superview else { return [] }

        return [
            superview.topAnchor.constraint(equalTo: topAnchor),
            superview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    func edgesToSuperviewEdges(exclude excludedAnchorType: AnchorType? = .none) -> [NSLayoutConstraint] {
        guard let superview = superview else { return [] }

        var constraints:[NSLayoutConstraint] = []

        if excludedAnchorType != .top {
            constraints.append(superview.topAnchor.constraint(equalTo: topAnchor))
        }
        if excludedAnchorType != .bottom {
            constraints.append(superview.bottomAnchor.constraint(equalTo: bottomAnchor))
        }
        if excludedAnchorType != .leading {
            constraints.append(superview.leadingAnchor.constraint(equalTo: leadingAnchor))
        }
        if excludedAnchorType != .trailing {
            constraints.append(superview.trailingAnchor.constraint(equalTo: trailingAnchor))
        }

        return constraints
    }

    func pinEdgesToSuperviewEdges() {

        NSLayoutConstraint.activate(edgesToSuperviewEdges())
    }

    func centerInSuperview() -> [NSLayoutConstraint] {
        guard let superview = superview else { return [] }

        return [
            superview.centerXAnchor.constraint(equalTo: centerXAnchor),
            superview.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
    }
}
