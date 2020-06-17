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
            nameLabel.text = displayName.localizedUppercase
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

            constraints.append(contentsOf: contentView.fitInSuperview(activate: false).values)
            constraints.append(contentsOf: badgeUserImageView.fitInSuperview(activate: false).values)

            conversationImageViewSize = conversationImageView.setDimensions(length: 80, activate: false)[.width]
            avatarViewSizeConstraint = avatarContainer.setDimensions(length: 80, activate: false)[.width]

            constraints.append(conversationImageViewSize!)
            constraints.append(avatarViewSizeConstraint!)

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

    private func updateForContext() {
        nameLabel.font = .smallLightFont
        nameLabel.textColor = ColorScheme.default.color(named: .textForeground, variant: .dark)

        badgeUserImageView.badgeColor = .white

        let squareImageWidth: CGFloat = 56
        avatarViewSizeConstraint?.constant = squareImageWidth
        conversationImageViewSize?.constant = squareImageWidth
    }

}
