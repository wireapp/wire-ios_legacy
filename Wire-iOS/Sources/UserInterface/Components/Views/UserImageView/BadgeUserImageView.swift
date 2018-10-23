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

import WireExtensionComponents

/**
 * A user image view that can display a badge on top for different connection states.
 */

@objc class BadgeUserImageView: UserImageView {

    /// The size of the badge icon.
    @objc var badgeIconSize: ZetaIconSize = .tiny {
        didSet {
            updateIconView(with: badgeIcon, animated: false)
        }
    }

    /// The color of the badge.
    @objc var badgeColor: UIColor = .white {
        didSet {
            updateIconView(with: badgeIcon, animated: false)
        }
    }

    /// The badge icon.
    @objc var badgeIcon: ZetaIconType = .none {
        didSet {
            updateIconView(with: badgeIcon, animated: false)
        }
    }

    private let badgeImageView = UIImageView()
    private let badgeShadow = UIView()

    // MARK: - Initialization

    @objc override convenience init(frame: CGRect) {
        self.init(size: .small)
    }
    
    override init(size: UserImageView.Size = .small) {
        super.init(size: size)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        isOpaque = false
        container.addSubview(badgeShadow)
        container.addSubview(badgeImageView)
    }

    private func configureConstraints() {
        badgeShadow.translatesAutoresizingMaskIntoConstraints = false
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // badgeShadow
            badgeShadow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            badgeShadow.topAnchor.constraint(equalTo: container.topAnchor),
            badgeShadow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            badgeShadow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            // badgeImageView
            badgeImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badgeImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    // MARK: - Updates

    override func updateUser() {
        super.updateUser()
        updateBadgeIcon()
    }

    override func userDidChange(_ changeInfo: UserChangeInfo) {
        super.userDidChange(changeInfo)

        if changeInfo.connectionStateChanged {
            self.updateBadgeIcon()
        }
    }

    /// Updates the badge icon.
    private func updateBadgeIcon() {
        guard let user = self.user?.zmUser else {
            badgeIcon = .none
            return
        }

        if user.isBlocked {
            badgeIcon = .block
        } else if user.isPendingApproval() {
            badgeIcon = .clock
        } else {
            badgeIcon = .none
        }
    }

    // MARK: - Interface

    /**
     * Updates the icon view with the specified icon, with an optional animation.
     * - parameter icon: The icon to show on the badge.
     * - parameter animated: Whether to animate the change.
     */

    func updateIconView(with icon: ZetaIconType, animated: Bool) {
        badgeImageView.image = nil

        if badgeIcon != .none {
            let hideBadge = {
                self.badgeImageView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
                self.badgeImageView.alpha = 0
            }

            let changeImage = {
                self.badgeImageView.image = UIImage(for: self.badgeIcon,
                                                    iconSize: self.badgeIconSize,
                                                    color: self.badgeColor)
            }

            let showBadge = {
                self.badgeImageView.transform = .identity
                self.badgeImageView.alpha = 1
            }

            let showShadow = {
                self.badgeShadow.backgroundColor = UIColor(white: 0, alpha: 0.5)
            }

            if animated {
                hideBadge()
                changeImage()
                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 15.0, options: [], animations: showBadge, completion: nil)
                UIView.wr_animate(easing: .easeOutQuart, duration: 0.15, animations: showShadow)
            } else {
                changeImage()
                showShadow()
            }

        } else {
            badgeShadow.backgroundColor = .clear
        }
    }

}
