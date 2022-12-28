//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents

final class TopPeopleCell: UICollectionViewCell {

    // MARK: - Properties

    var user: UserType? {
        didSet {
            badgeUserImageView.user = user
            displayName = user?.name ?? ""
        }
    }

    var conversation: ZMConversation? {
        didSet {
            user = conversation?.connectedUser
            conversationImageView.image = nil
        }
    }

    var displayName: String = "" {
        didSet {
            accessibilityValue = displayName
            nameLabel.text = displayName.localized
        }
    }

    private let badgeUserImageView = BadgeUserImageView()
    private let conversationImageView = UIImageView()
    private let nameLabel = UILabel()
    private let avatarContainer = UIView()

    private var avatarViewSizeConstraint: NSLayoutConstraint?
    private var conversationImageViewSize: NSLayoutConstraint?
    private var initialConstraintsCreated = false

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityIdentifier = "TopPeopleCell"
        isAccessibilityElement = true

        setupViews()
        setNeedsUpdateConstraints()
        updateForContext()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override func prepareForReuse() {
        super.prepareForReuse()
        conversationImageView.image = nil
        conversationImageView.isHidden = false
        badgeUserImageView.isHidden = false
    }

    private func setupViews() {
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.textAlignment = .center

        badgeUserImageView.removeFromSuperview()
        badgeUserImageView.initialsFont = .systemFont(ofSize: 11, weight: .light)
        badgeUserImageView.userSession = ZMUserSession.shared()
        badgeUserImageView.isUserInteractionEnabled = false
        badgeUserImageView.wr_badgeIconSize = 16
        badgeUserImageView.accessibilityIdentifier = "TopPeopleAvatar"
        avatarContainer.addSubview(badgeUserImageView)

        [avatarContainer, nameLabel, conversationImageView].forEach(contentView.addSubview)
    }

    override func updateConstraints() {
        if !initialConstraintsCreated {
            [contentView, badgeUserImageView, avatarContainer, conversationImageView, nameLabel].prepareForLayout()

            var constraints: [NSLayoutConstraint] = []
            constraints.append(contentsOf: [contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                                            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                            contentView.topAnchor.constraint(equalTo: topAnchor),
                                            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)])

            constraints.append(contentsOf: [badgeUserImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
                                            badgeUserImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
                                            badgeUserImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
                                            badgeUserImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor)])

            conversationImageViewSize = conversationImageView.widthAnchor.constraint(equalToConstant: 80)
            avatarViewSizeConstraint = avatarContainer.widthAnchor.constraint(equalToConstant: 80)
            constraints.append(conversationImageViewSize!)
            constraints.append(avatarViewSizeConstraint!)

            constraints.append(contentsOf: [avatarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                            avatarContainer.topAnchor.constraint(equalTo: contentView.topAnchor)])

            constraints.append(contentsOf: [conversationImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                            conversationImageView.topAnchor.constraint(equalTo: contentView.topAnchor)])

            constraints.append(nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 4))

            nameLabel.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor).isActive = true
            nameLabel.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor).isActive = true

            NSLayoutConstraint.activate(constraints)
            initialConstraintsCreated = true

            updateForContext()
        }

        super.updateConstraints()
    }

    private func updateForContext() {
        nameLabel.font = FontSpec.bodyTwoSemibold.font!
        nameLabel.textColor = SemanticColors.Label.textDefault

        badgeUserImageView.badgeColor = .white

        let squareImageWidth: CGFloat = 56
        avatarViewSizeConstraint?.constant = squareImageWidth
        conversationImageViewSize?.constant = squareImageWidth
    }

}
