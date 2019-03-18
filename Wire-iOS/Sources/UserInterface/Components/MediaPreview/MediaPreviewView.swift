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

@objcMembers
final class MediaPreviewView: UIView {
    private(set) var playButton: IconButton!
    private(set) var titleLabel: UILabel!
    private(set) var providerImageView: UIImageView!
    private(set) var previewImageView: UIImageView!
    private(set) var containerView: UIView!
    private(set) var contentView: UIView!
    private(set) var overlayView: UIView!

    init() {
        super.init(frame: .zero)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupLayout()
        updateCorners()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorners()
    }

    private func updateCorners() {
        containerView.layer.cornerRadius = 4
    }

    private func setupSubviews() {
        contentView = UIView()
        addSubview(contentView)

        containerView = UIView()
        containerView.clipsToBounds = true
        contentView.addSubview(containerView)


        previewImageView = UIImageView()
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        containerView.addSubview(previewImageView)

        overlayView = UIView()
        overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.48)
        containerView.addSubview(overlayView)

        titleLabel = UILabel()
        titleLabel?.font = UIFont.normalLightFont
        titleLabel?.textColor = UIColor.white
        titleLabel?.numberOfLines = 2
        if let titleLabel = titleLabel {
            containerView.addSubview(titleLabel)
        }

        playButton = IconButton()
        playButton.setIcon(.play, with: .large, for: .normal)
        playButton.setIconColor(UIColor.white, for: UIControl.State.normal)
        containerView.addSubview(playButton)

        providerImageView = UIImageView()
        providerImageView.alpha = 0.4
        containerView.addSubview(providerImageView)
    }

    private func setupLayout() {
        [contentView, containerView, previewImageView, overlayView, titleLabel, providerImageView, playButton].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints: [NSLayoutConstraint] = []

        [contentView, containerView, previewImageView, overlayView].forEach() {
            constraints += $0.fitInSuperview(activate: false).values
        }


        constraints += [titleLabel.pinToSuperview(anchor: .top, inset: 12, activate: false),
                        titleLabel.pinToSuperview(anchor: .leading, inset: 12, activate: false),
                        providerImageView.pinToSuperview(anchor: .top, inset: 15, activate: false),
                        providerImageView.pinToSuperview(anchor: .trailing, inset: 12, activate: false),
                        providerImageView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)]

        titleLabel?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        constraints += playButton.centerInSuperview(activate: false)

        NSLayoutConstraint.activate(constraints)
    }
}

