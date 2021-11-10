//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel
import FLAnimatedImage

final class ImageMessageView: UIView {

    private let imageView = FLAnimatedImageView()
    private let userImageView = UserImageView(size: .tiny)
    private let userNameLabel = UILabel()
    private let userImageViewContainer = UIView()
    private let dotsLoadingView = ThreeDotsLoadingView()
    private var aspectRatioConstraint: NSLayoutConstraint? = .none
    private var imageSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var user: UserType? {
        didSet {
            if let user = user {
                userNameLabel.textColor = UIColor.nameColor(for: user.accentColorValue, variant: .light)
                userNameLabel.text = user.name
                userImageView.user = user
            }
        }
    }

    var message: ZMConversationMessage? {
        didSet {
            if let message = message {
                user = message.senderUser

                updateForImage()
            }
        }
    }

    private func updateForImage() {
        if let message = message,
           let imageMessageData = message.imageMessageData,
           let imageData = imageMessageData.imageData,
           !imageData.isEmpty {

            dotsLoadingView.stopProgressAnimation()
            dotsLoadingView.isHidden = true

            if imageMessageData.isAnimatedGIF {
                let image = FLAnimatedImage(animatedGIFData: imageData)
                imageSize = image?.size ?? .zero
                imageView.animatedImage = image
            } else {
                let image = UIImage(data: imageData, scale: 2.0)
                imageSize = image?.size ?? .zero
                imageView.image = image
            }
        } else {
            dotsLoadingView.isHidden = false
            dotsLoadingView.startProgressAnimation()
        }
        updateImageLayout()
    }

    private func updateImageLayout() {
        guard bounds.width != 0, aspectRatioConstraint == .none, imageSize.width != 0 else {
            return
        }

        imageView.translatesAutoresizingMaskIntoConstraints = false

        if imageSize.width / 2.0 > imageView.bounds.width {
            aspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: imageSize.height / imageSize.width)
        } else {
            imageView.contentMode = .left
            aspectRatioConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        }

        aspectRatioConstraint?.isActive = true
        setNeedsLayout()
    }

    private func createViews() {
        userImageViewContainer.addSubview(userImageView)

        [imageView, userImageViewContainer, userNameLabel].forEach(addSubview)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        userNameLabel.font = UIFont.systemFont(ofSize: 12, contentSizeCategory: .small, weight: .medium)
        userImageView.initialsFont = UIFont.systemFont(ofSize: 11, contentSizeCategory: .small, weight: .light)

        addSubview(dotsLoadingView)

        createConstraints()

        updateForImage()
    }

    private func createConstraints() {
        [imageView,
         userImageView,
         userImageViewContainer,
         userNameLabel,
         dotsLoadingView].prepareForLayout()

        NSLayoutConstraint.activate([
            userImageViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            userImageViewContainer.widthAnchor.constraint(equalToConstant: 48),
            userImageViewContainer.heightAnchor.constraint(equalToConstant: 24),
            userImageViewContainer.topAnchor.constraint(equalTo: topAnchor),

            userImageView.topAnchor.constraint(equalTo: userImageViewContainer.topAnchor),
            userImageView.bottomAnchor.constraint(equalTo: userImageViewContainer.bottomAnchor),
            userImageView.centerXAnchor.constraint(equalTo: userImageViewContainer.centerXAnchor),
            userImageView.widthAnchor.constraint(equalTo: userImageViewContainer.heightAnchor),

            userNameLabel.leadingAnchor.constraint(equalTo: userImageViewContainer.trailingAnchor),
            userNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            userNameLabel.centerYAnchor.constraint(equalTo: userImageView.centerYAnchor),

            imageView.topAnchor.constraint(equalTo: userImageViewContainer.bottomAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: userImageViewContainer.trailingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),

            dotsLoadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            dotsLoadingView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateImageLayout()
    }
}
