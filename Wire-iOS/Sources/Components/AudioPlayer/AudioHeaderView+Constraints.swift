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

extension AudioHeaderView {
    @objc
    func configureConstraints() {
        providerImageContainer.translatesAutoresizingMaskIntoConstraints = false
        providerButton.translatesAutoresizingMaskIntoConstraints = false
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        providerImageContainerWidthConstraint = providerImageContainer.widthAnchor.constraint(equalToConstant: UIView.conversationLayoutMargins.left)
        textTrailingConstraint = textStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIView.conversationLayoutMargins.right)

        NSLayoutConstraint.activate([
            // providerImageContainer
            providerImageContainerWidthConstraint,
            providerImageContainer.topAnchor.constraint(equalTo: topAnchor),
            providerImageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            providerImageContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            // providerButton
            providerButton.centerXAnchor.constraint(equalTo: providerImageContainer.centerXAnchor),
            providerButton.centerYAnchor.constraint(equalTo: providerImageContainer.centerYAnchor),
            providerButton.widthAnchor.constraint(equalToConstant: 28),
            providerButton.heightAnchor.constraint(equalToConstant: 28),
            // textStackView
            textStackView.leadingAnchor.constraint(equalTo: providerImageContainer.trailingAnchor),
            textStackView.centerYAnchor.constraint(equalTo: providerImageContainer.centerYAnchor),
            textTrailingConstraint
            ])
    }
}
