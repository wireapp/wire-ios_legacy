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

extension ConversationListItemView {
    static let minHeight: CGFloat = 64

    @objc func createConstraints() {
        guard let labelsContainerSuperview = labelsContainer.superview,
        let lineViewSuperview = lineView.superview else { return }

        [labelsContainer, titleField, avatarContainer, avatarView, lineView, subtitleField].forEach{
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        let leftMargin: CGFloat = 64.0

        var constraints: [NSLayoutConstraint] = []
        constraints += [heightAnchor.constraint(greaterThanOrEqualToConstant: ConversationListItemView.minHeight)]

        
        constraints += avatarContainer.edgesToSuperviewEdges(exclude: .trailing)
        constraints += [avatarContainer.trailingAnchor.constraint(equalTo: titleField.leadingAnchor)]
        constraints += avatarView.centerInSuperview()

        constraints += titleField.edgesToSuperviewEdges(exclude: .bottom)
        constraints += [subtitleField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 2)]
        constraints += subtitleField.edgesToSuperviewEdges(exclude: .top)

        constraints +=
            [labelsContainer.topAnchor.constraint(greaterThanOrEqualTo: labelsContainerSuperview.topAnchor, constant: 8),
             labelsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftMargin),
             labelsContainer.trailingAnchor.constraint(equalTo: rightAccessory.leadingAnchor, constant: -8),
             labelsContainer.bottomAnchor.constraint(lessThanOrEqualTo: labelsContainerSuperview.bottomAnchor, constant: -8)]

        titleOneLineConstraint =
            titleField.centerYAnchor.constraint(equalTo:centerYAnchor)
        constraints += [titleOneLineConstraint]

        constraints += [
            rightAccessory.centerYAnchor.constraint(equalTo:centerYAnchor),
            rightAccessory.trailingAnchor.constraint(equalTo:trailingAnchor, constant: -16),

            lineView.heightAnchor.constraint(equalToConstant: UIScreen.hairline),
            lineView.bottomAnchor.constraint(equalTo: lineViewSuperview.bottomAnchor),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.leadingAnchor.constraint(equalTo: titleField.leadingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)


        // inactive constraints
        titleTwoLineConstraint = labelsContainer.centerYAnchor.constraint(equalTo: labelsContainerSuperview.centerYAnchor)
    }
}
