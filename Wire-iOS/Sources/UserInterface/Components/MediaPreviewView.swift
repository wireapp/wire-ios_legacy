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

import UIKit
import WireCommonComponents

@objc final class MediaPreviewView: RoundedView {

    let playButton = IconButton()
    let titleLabel = UILabel()
    let providerImageView = UIImageView()
    let previewImageView = ImageResourceView()
    let containerView = UIView()
    let contentView = UIView()
    let overlayView = UIView()

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupSubviews()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        shape = .rounded(radius: 4)
        addSubview(contentView)

        containerView.clipsToBounds = true
        contentView.addSubview(containerView)

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        containerView.addSubview(previewImageView)

        overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.48)
        containerView.addSubview(overlayView)

        titleLabel.font = UIFont.normalLightFont
        titleLabel.textColor = UIColor.white
        titleLabel.numberOfLines = 2
        containerView.addSubview(titleLabel)

        playButton.setIcon(.play, with: .large, for: .normal)
        playButton.setIconColor(UIColor.white, for: UIControl.State.normal)
        containerView.addSubview(playButton)

        providerImageView.alpha = 0.4
        containerView.addSubview(providerImageView)
    }

    private func setupLayout() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        providerImageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // contentView
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // containerView
            containerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // previewImageView
            previewImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            previewImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // overlayView
            overlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // titleLabel
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),

            // providerImageView
            providerImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            providerImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            providerImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),

            // playButton
            playButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor)
        ])
    }

}
