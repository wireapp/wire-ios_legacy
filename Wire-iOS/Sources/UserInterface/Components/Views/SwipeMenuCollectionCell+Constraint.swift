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
        defer { super.updateConstraints() }

        guard !hasCreatedSwipeMenuConstraints else { return }
        guard let swipeView = swipeView  else { return }
        hasCreatedSwipeMenuConstraints = true

        swipeViewHorizontalConstraint = swipeView.leftAnchor.constraint(equalTo: swipeView.leftAnchor)
        menuViewToSwipeViewLeftConstraint = menuView.rightAnchor.constraint(equalTo: swipeView.leftAnchor)

        ///TODO: do not use priority and break this constraint
        maxMenuViewToSwipeViewLeftConstraint = menuView.rightAnchor.constraint(equalTo: self.leftAnchor, constant: maxVisualDrawerOffset)
        maxMenuViewToSwipeViewLeftConstraint.priority = .defaultLow

        let swipeViewConstraints : [NSLayoutConstraint] = [
            swipeViewHorizontalConstraint!,
            contentView.widthAnchor.constraint(equalTo: swipeView.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: swipeView.heightAnchor),
            contentView.centerYAnchor.constraint(equalTo: swipeView.centerYAnchor),

            separatorLine.widthAnchor.constraint(equalToConstant: UIScreen.hairline),
            separatorLine.heightAnchor.constraint(equalToConstant: 25),
            separatorLine.centerYAnchor.constraint(equalTo: swipeView.centerYAnchor),
            separatorLine.rightAnchor.constraint(equalTo: menuView.rightAnchor),

            menuView.topAnchor.constraint(equalTo: swipeView.topAnchor),
            menuView.bottomAnchor.constraint(equalTo: swipeView.bottomAnchor),
            menuViewToSwipeViewLeftConstraint!,
            maxMenuViewToSwipeViewLeftConstraint!
        ]

        NSLayoutConstraint.activate(swipeViewConstraints)
    }
}
