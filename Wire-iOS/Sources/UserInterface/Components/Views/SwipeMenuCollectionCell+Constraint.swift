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

extension SwipeMenuCollectionCell {
    open override func updateConstraints() {

        if hasCreatedSwipeMenuConstraints {
            super.updateConstraints()
            return
        }

        guard let swipeView = swipeView else {
            super.updateConstraints()
            return
        }

        hasCreatedSwipeMenuConstraints = true

        swipeViewHorizontalConstraint = swipeView.leftAnchor.constraint(equalTo: contentView.leftAnchor)

        /// menu view attachs to swipeView before reaching max offset
        menuViewToSwipeViewLeftConstraint = menuView.rightAnchor.constraint(equalTo: swipeView.leftAnchor)

        /// menu view attachs to content view after reaching max offset
        maxMenuViewToSwipeViewLeftConstraint = menuView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: maxVisualDrawerOffset)

        [swipeView, separatorLine, menuView].forEach{$0.translatesAutoresizingMaskIntoConstraints = false}

        let constraints : [NSLayoutConstraint] = [
            swipeViewHorizontalConstraint!,
            swipeView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            swipeView.heightAnchor.constraint(equalTo: contentView.heightAnchor),

            swipeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            separatorLine.widthAnchor.constraint(equalToConstant: UIScreen.hairline),
            separatorLine.heightAnchor.constraint(equalToConstant: 25),
            separatorLine.centerYAnchor.constraint(equalTo: swipeView.centerYAnchor),
            separatorLine.rightAnchor.constraint(equalTo: menuView.rightAnchor),

            menuView.topAnchor.constraint(equalTo: swipeView.topAnchor),
            menuView.bottomAnchor.constraint(equalTo: swipeView.bottomAnchor),
            menuViewToSwipeViewLeftConstraint!,
        ]

        NSLayoutConstraint.activate(constraints)

        super.updateConstraints()
    }

    /// Checks on the @c maxVisualDrawerOffset and switches the prio's of the constraint
    @objc func checkAndUpdateMaxVisualDrawerOffsetConstraints(_ visualDrawerOffset: CGFloat) {
        if visualDrawerOffset >= menuView.frame.width + maxVisualDrawerOffset {
            menuViewToSwipeViewLeftConstraint?.isActive = false
            maxMenuViewToSwipeViewLeftConstraint?.isActive = true
        } else {
            disableMaxVisualDrawerOffsetConstraints()
        }
    }

    @objc func disableMaxVisualDrawerOffsetConstraints() {
        maxMenuViewToSwipeViewLeftConstraint?.isActive = false
        menuViewToSwipeViewLeftConstraint?.isActive = true
    }
}
