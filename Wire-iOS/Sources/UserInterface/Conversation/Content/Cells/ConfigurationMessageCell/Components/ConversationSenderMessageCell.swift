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

import UIKit

class ConversationSenderMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let user: UserType
        let showTrash: Bool
    }

    var isSelected: Bool = false
    private let senderView = SenderCellComponent()
    private let trashImageView = UIImageView()

    private var trashImageViewTrailing: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    func configure(with object: Configuration) {
        senderView.configure(with: object.user)
        trashImageView.isHidden = !object.showTrash
    }

    private func configureSubviews() {
        let trashColor = UIColor(scheme: .iconNormal)
        trashImageView.image = UIImage(for: .trash, iconSize: .messageStatus, color: trashColor)

        addSubview(senderView)
        addSubview(trashImageView)
    }

    private func configureConstraints() {
        senderView.translatesAutoresizingMaskIntoConstraints = false
        trashImageView.translatesAutoresizingMaskIntoConstraints = false

        trashImageViewTrailing = trashImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UIView.conversationLayoutMargins.right)

        NSLayoutConstraint.activate([
            // trashImageView
            trashImageViewTrailing,
            trashImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            // senderView
            senderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            senderView.topAnchor.constraint(equalTo: topAnchor),
            senderView.trailingAnchor.constraint(equalTo: trashImageView.leadingAnchor, constant: -8),
            senderView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        trashImageViewTrailing.constant = -UIView.conversationLayoutMargins.right
    }

}

class ConversationSenderMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSenderMessageCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return true
    }

    init(sender: UserType, showTrash: Bool) {
        self.configuration = View.Configuration(user: sender, showTrash: showTrash)
    }
}
