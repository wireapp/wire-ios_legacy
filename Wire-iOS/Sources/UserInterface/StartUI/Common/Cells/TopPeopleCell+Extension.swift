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

extension TopPeopleCell {
    override open func updateConstraints() {
        if !initialConstraintsCreated {
            [contentView, badgeUserImageView, avatarContainer, conversationImageView, nameLabel].forEach() {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }

            var constraints: [NSLayoutConstraint] = []

            constraints.append(contentsOf: contentView.fitInSuperview(activate: false).values)
            constraints.append(contentsOf: badgeUserImageView.fitInSuperview(activate: false).values)

            conversationImageViewSize = conversationImageView.setDimensions(length: 80, activate: false)[.width]
            avatarViewSizeConstraint = avatarContainer.setDimensions(length: 80, activate: false)[.width]

            constraints.append(conversationImageViewSize)
            constraints.append(avatarViewSizeConstraint)

            constraints.append(contentsOf: avatarContainer.fitInSuperview(exclude: [.bottom, .trailing], activate: false).values)
            constraints.append(contentsOf: conversationImageView.fitInSuperview(exclude: [.bottom, .trailing], activate: false).values)

            constraints.append(nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 8))

            constraints.append(contentsOf: nameLabel.pin(to: avatarContainer,
                          with: EdgeInsets(top: .nan, leading: 0, bottom: .nan, trailing: 0),
                          exclude: [.top, .bottom], activate: false).values)

            NSLayoutConstraint.activate(constraints)

            initialConstraintsCreated = true

            updateForContext()
        }
        super.updateConstraints()
    }

}
