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

import WireSyncEngine

/**
 * A view that displays the avatar for a remote user.
 */

@objc open class UserImageView: AvatarImageView, ZMUserObserver {

    /**
     * The different sizes for the avatar image.
     */

    @objc(UserImageViewSize) public enum Size: Int {
        case tiny = 16
        case badge = 24
        case small = 32
        case normal = 64
        case big = 320
    }

    // MARK: - Interface Properties

    /// The size of the avatar.
    @objc public var size: Size {
        didSet {
            updateUserImage()
        }
    }

    /// Whether the image should be desaturated, e.g. for unconnected users.
    @objc public var shouldDesaturate: Bool = true

    /// Whether the badge indicator is enabled.
    public var indicatorEnabled: Bool = false {
        didSet {
            badgeIndicator.isHidden = !indicatorEnabled
        }
    }

    private let badgeIndicator = RoundedView()

    // MARK: - Remote User

    /// The user session to use to download images.
    @objc public var userSession: ZMUserSession? {
        didSet {
            updateUser()
        }
    }

    /// The user to display the avatar of.
    @objc public var user: UserType? {
        didSet {
            updateUser()
        }
    }

    private var userObserverToken: Any?

    // MARK: - Initialization

    public override init(frame: CGRect) {
        self.size = .small
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    public init(size: Size = .small) {
        self.size = size
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    deinit {
        userObserverToken = nil
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: size.rawValue, height: size.rawValue)
    }

    private func configureSubviews() {
        accessibilityElementsHidden = true

        badgeIndicator.backgroundColor = .red
        badgeIndicator.isHidden = true
        badgeIndicator.shape = .circle
        addSubview(badgeIndicator)
    }

    private func configureConstraints() {
        badgeIndicator.translatesAutoresizingMaskIntoConstraints = false

        setContentHuggingPriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            badgeIndicator.topAnchor.constraint(equalTo: topAnchor),
            badgeIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            badgeIndicator.heightAnchor.constraint(equalTo: badgeIndicator.widthAnchor),
            badgeIndicator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/3)
        ])
    }

    // MARK: - Interface

    /// Returns the appropriate border width for the user.
    private func borderWidth(for user: UserType) -> CGFloat {
        return user.isServiceUser ? 0.5 : 0
    }

    /// Returns the appropriate border color for the user.
    private func borderColor(for user: UserType) -> CGColor? {
        return user.isServiceUser ? UIColor.black.withAlphaComponent(0.08).cgColor : nil
    }

    /// Returns the placeholder background color for the user.
    private func containerBackgroundColor(for user: UserType) -> UIColor? {
        let isWireless = user.zmUser?.isWirelessUser == true

        switch self.avatar {
        case .image?, nil:
            return user.isServiceUser ? .white : .clear
        case .text?:
            if user.isConnected || user.isSelfUser || user.isTeamMember || isWireless {
                return user.indexedAccentColor
            } else {
                return UIColor(white: 0.8, alpha: 1)
            }
        }
    }

    /// Returns the appropriate avatar shape for the user.
    private func shape(for user: UserType) -> AvatarImageView.Shape {
        return user.isServiceUser ? .relative : .circle
    }

    // MARK: - Changing the Content

    /**
     * Sets the avatar for the user with an optional animation.
     * - parameter avatar: The avatar of the user.
     * - parameter user: The currently displayed user.
     * - parameter animated: Whether to animate the change.
     */

    func setAvatar(_ avatar: Avatar, user: UserType, animated: Bool) {
        let updateBlock = {
            self.avatar = avatar
            self.container.backgroundColor = self.containerBackgroundColor(for: user)
        }

        if animated {
            UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: updateBlock, completion: nil)
        } else {
            updateBlock()
        }
    }

    /// Updates the image for the user.
    fileprivate func updateUserImage() {
        guard let user = user, let userSession = userSession else { return }

        var desaturate = false
        if shouldDesaturate {
            desaturate = !user.isConnected && !user.isSelfUser && !user.isTeamMember && !user.isServiceUser
        }

        user.fetchProfileImage(session: userSession, sizeLimit: size.rawValue, desaturate: desaturate, completion: { [weak self] (image, cacheHit) in
            // Don't set image if nil or if user has changed during fetch
            guard let image = image, user.isEqual(self?.user) else { return }
            self?.setAvatar(.image(image), user: user, animated: !cacheHit)
        })
    }

    // MARK: - Updates

    open func userDidChange(_ changeInfo: UserChangeInfo) {
        // Check for potential image changes
        if size == .big{
            if changeInfo.imageMediumDataChanged || changeInfo.connectionStateChanged {
                updateUserImage()
            }
        } else {
            if changeInfo.imageSmallProfileDataChanged || changeInfo.connectionStateChanged || changeInfo.teamsChanged {
                updateUserImage()
            }
        }

        // Change for accent color changes
        if changeInfo.accentColorValueChanged {
            updateIndicatorColor()
        }
    }

    /// Called when the user or user session changes.
    open func updateUser() {
        guard let user = self.user, let initials = user.initials else {
            return
        }

        let defaultAvatar = Avatar.text(initials.localizedUppercase)
        setAvatar(defaultAvatar, user: user, animated: false)

        if let userSession = self.userSession {
            userObserverToken = UserChangeInfo.add(observer: self, for: user, userSession: userSession)
        }

        updateForServiceUserIfNeeded(user)
        updateIndicatorColor()
        updateUserImage()
    }

    /// Updates the color of the badge indicator.
    private func updateIndicatorColor() {
        self.badgeIndicator.backgroundColor = user?.indexedAccentColor
    }

    /// Updates the interface to reflect if the user is a service user or not.
    private func updateForServiceUserIfNeeded(_ user: UserType) {
        shape = shape(for: user)
        container.layer.borderColor = borderColor(for: user)
        container.layer.borderWidth = borderWidth(for: user)
        container.backgroundColor = containerBackgroundColor(for: user)
    }

}
