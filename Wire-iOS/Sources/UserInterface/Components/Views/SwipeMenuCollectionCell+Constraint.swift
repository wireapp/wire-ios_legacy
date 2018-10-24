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

        swipeViewHorizontalConstraint = swipeView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0)
        menuViewToSwipeViewLeftConstraint = menuView.rightAnchor.constraint(equalTo: swipeView.leftAnchor)

        ///TODO: do not use priority and break this constraint
        maxMenuViewToSwipeViewLeftConstraint = menuView.rightAnchor.constraint(equalTo: self.leftAnchor, constant: maxVisualDrawerOffset)
        maxMenuViewToSwipeViewLeftConstraint.priority = .defaultLow
        [swipeView, separatorLine, menuView].forEach{$0.translatesAutoresizingMaskIntoConstraints = false}

        let constraints : [NSLayoutConstraint] = [
            swipeViewHorizontalConstraint!,
            swipeView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0),
            swipeView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1.0),

            swipeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            separatorLine.widthAnchor.constraint(equalToConstant: UIScreen.hairline),
            separatorLine.heightAnchor.constraint(equalToConstant: 25),
            separatorLine.centerYAnchor.constraint(equalTo: swipeView.centerYAnchor),
            separatorLine.rightAnchor.constraint(equalTo: menuView.rightAnchor),

            menuView.topAnchor.constraint(equalTo: swipeView.topAnchor),
            menuView.bottomAnchor.constraint(equalTo: swipeView.bottomAnchor),
            menuViewToSwipeViewLeftConstraint!,
            maxMenuViewToSwipeViewLeftConstraint!
        ]

        NSLayoutConstraint.activate(constraints)

//        swipeView.frame =
        super.updateConstraints()
    }
}
