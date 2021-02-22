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

/**
 * A view that displays the avatar of a user, either as text initials or as an image.
 */

class AvatarImageView: UIControl {

    /**
     * The different, mutually-exclusive forms of avatars
     */

    enum Avatar: Equatable {
        case image(UIImage)
        case text(String)
    }

    /**
     * The different shapes of avatars.
     */

    enum Shape {
        case rectangle, circle, relative
    }

    // MARK: - Properties

    /// The avatar to display.
    var avatar: Avatar? {
        didSet {
            if avatar != oldValue {
                updateAvatar()
            }
        }
    }

    /// The shape of the avatar
    var shape: Shape = .circle {
        didSet {
            if shape != oldValue {
                updateShape()
            }
        }
    }

    /// Whether to allow initials.
    var allowsInitials: Bool = true {
        didSet {
            if allowsInitials != oldValue {
                updateAvatar()
            }
        }
    }

    /// The background color for the image.
    var imageBackgroundColor: UIColor? {
        get { return container.backgroundColor }
        set {
            container.backgroundColor = newValue
        }
    }

    /// The font to use of the initials label.
    var initialsFont: UIFont {
        get { return initialsLabel.font }
        set { initialsLabel.font = newValue }
    }

    /// The color to use for the initials label.
    var initialsColor: UIColor {
        get { return initialsLabel.textColor }
        set { initialsLabel.textColor = newValue }
    }

    override var contentMode: UIView.ContentMode {
        didSet {
            if contentMode != oldValue {
                imageView.contentMode = contentMode
            }
        }
    }

    /// The view that contains the avatar.
    var container = RoundedView()

    private let imageView = UIImageView()
    private let initialsLabel = UILabel()

    // MARK: - Initialization

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

    private func configureSubviews() {
        contentMode = .scaleAspectFill
        
        isOpaque = false
        imageView.isOpaque = false
        container.backgroundColor = .yellow

        initialsLabel.textColor = .white
        initialsLabel.font = .systemFont(ofSize: 17)

        container.clipsToBounds = true
        container.isUserInteractionEnabled = false

        imageView.isAccessibilityElement = false
        initialsLabel.isAccessibilityElement = false

        addSubview(container)
        container.addSubview(imageView)
        container.addSubview(initialsLabel)

        updateAvatar()
        updateShape()
    }

    private func configureConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // containerView
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.widthAnchor.constraint(equalTo: container.heightAnchor),

            // imageView
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            // initials
            initialsLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    /**
     * Updates the image constraints hugging and resistance priorities.
     * - parameter resistance: The compression resistance priority.
     * - parameter hugging: The content hugging priority.
     */

    func setImageConstraint(resistance: Float, hugging: Float) {
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: hugging), for: .vertical)
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: hugging), for: .horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: resistance), for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: resistance), for: .horizontal)
    }

    // MARK: - Content

    /// Updates the displayed avatar.
    private func updateAvatar() {
        switch avatar {
        case .image(let image)?:
            imageView.image = image
            initialsLabel.text = nil
            imageView.isHidden = false
            initialsLabel.isHidden = true

        case .text(let text)?:
            guard allowsInitials else { fallthrough }

            imageView.image = nil
            initialsLabel.text = text
            imageView.isHidden = true
            initialsLabel.isHidden = false

        case .none:
            imageView.image = nil
            initialsLabel.text = nil
            imageView.isHidden = true
            initialsLabel.isHidden = true
        }
    }

    /// Updates the shape of the displayed avatar.
    private func updateShape() {
        switch shape {
        case .circle:
            container.shape = .circle
        case .rectangle:
            container.shape = .rectangle
        case .relative:
            container.shape = .relative(multiplier: 1/6, dimension: .height)
        }
    }

}
