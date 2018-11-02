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

extension AnimatedListMenuView {
    open override func updateConstraints() {
        if initialConstraintsCreated {
            super.updateConstraints()
            return
        }

        let dotWidth: CGFloat = 4

        let dotViews = [leftDotView, centerDotView, rightDotView]

        dotViews.forEach{$0.translatesAutoresizingMaskIntoConstraints = false}
        self.translatesAutoresizingMaskIntoConstraints = false


        centerToRightDistanceConstraint = centerDotView.rightAnchor.constraint(equalTo: rightDotView.leftAnchor, constant: centerToRightDistance(forProgress: progress))

        leftToCenterDistanceConstraint = leftDotView.rightAnchor.constraint(equalTo: centerDotView.leftAnchor, constant: leftToCenterDistance(forProgress: progress))

        let leftDotLeftConstraint = leftDotView.leftAnchor.constraint(equalTo: self.leftAnchor)

        dotViews.forEach{$0.setDimensions(length: dotWidth)}

        let subviewConstraints : [NSLayoutConstraint] = [
            leftDotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            centerDotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rightDotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            rightDotView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8),
            leftDotLeftConstraint,

            centerToRightDistanceConstraint,
            leftToCenterDistanceConstraint
        ]
        NSLayoutConstraint.activate(subviewConstraints)

        initialConstraintsCreated = true

        super.updateConstraints()
    }

    @objc
    func centerToRightDistance(forProgress progress: CGFloat) -> CGFloat {
        return -(4 + (10 * (1 - progress)))
    }

    @objc
    func leftToCenterDistance(forProgress progress: CGFloat) -> CGFloat {
        return -(4 + (20 * (1 - progress)))
    }

}
