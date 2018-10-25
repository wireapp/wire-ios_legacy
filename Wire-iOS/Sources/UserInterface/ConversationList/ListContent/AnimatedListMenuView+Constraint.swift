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
        super.updateConstraints()
        if !initialConstraintsCreated {
            let dotWidth: CGFloat = 4
            let dotSize: CGSize? = [dotWidth, dotWidth]
            leftDotView.autoAlignAxis(toSuperviewAxis: ALAxisHorizontal)
            centerDotView.autoAlignAxis(toSuperviewAxis: ALAxisHorizontal)
            rightDotView.autoAlignAxis(toSuperviewAxis: ALAxisHorizontal)
            leftDotView.autoSetDimensions(to: dotSize)
            centerDotView.autoSetDimensions(to: dotSize)
            rightDotView.autoSetDimensions(to: dotSize)
            rightDotView.autoPinEdge(toSuperviewEdge: ALEdgeRight, withInset: 8)
            centerToRightDistanceConstraint = centerDotView.autoPinEdge(ALEdgeRight, toEdge: ALEdgeLeft, ofView: rightDotView, withOffset: centerToRightDistance(forProgress: progress))
            leftToCenterDistanceConstraint = leftDotView.autoPinEdge(ALEdgeRight, toEdge: ALEdgeLeft, ofView: centerDotView, withOffset: leftToCenterDistance(forProgress: progress))
            initialConstraintsCreated = true
        }
    }
}
