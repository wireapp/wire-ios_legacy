//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension MediaBar {
    override open func updateConstraints() {
        if !initialConstraintsCreated {
            initialConstraintsCreated = true

            let iconSize: CGFloat = 16
            let buttonInsets: CGFloat = traitCollection.horizontalSizeClass == .regular ? 32 : 16

            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.fitInSuperview()

            titleLabel.pinToSuperview(axisAnchor: .centerY)

//            titleLabel?.autoAlignAxis(ALAxisHorizontal, toSameAxisOf: contentView)
            titleLabel?.autoPinEdge(ALEdgeLeft, toEdge: ALEdgeRight, ofView: playPauseButton, withOffset: 8.0)

            playPauseButton.autoSetDimensions(to: [iconSize, iconSize])
            playPauseButton.autoAlignAxis(ALAxisHorizontal, toSameAxisOf: contentView)
            playPauseButton.autoPinEdge(toSuperviewEdge: ALEdgeLeft, withInset: buttonInsets)

            closeButton.autoSetDimensions(to: [iconSize, iconSize])
            closeButton.autoAlignAxis(ALAxisHorizontal, toSameAxisOf: contentView)
            closeButton.autoPinEdge(ALEdgeLeft, toEdge: ALEdgeRight, ofView: titleLabel, withOffset: 8.0)
            closeButton.autoPinEdge(toSuperviewEdge: ALEdgeRight, withInset: buttonInsets)

            bottomSeparatorLine.autoSetDimension(ALDimensionHeight, toSize: 0.5)
            bottomSeparatorLine.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: ALEdgeTop)
        }

        super.updateConstraints()
    }

}
