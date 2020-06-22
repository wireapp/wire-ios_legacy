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

final class MediaBar: UIView {
    private(set) var titleLabel: UILabel!
    private(set) var playPauseButton: IconButton!
    private(set) var closeButton: IconButton!

    private var bottomSeparatorLine: UIView!
    private let contentView = UIView()
    private var initialConstraintsCreated = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(contentView)

        createTitleLabel()
        createPlayPauseButton()
        createCloseButton()
        createBorderView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createTitleLabel() {
        titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.accessibilityIdentifier = "playingMediaTitle"
        titleLabel.font = UIFont.smallRegularFont
        titleLabel.textColor = UIColor.from(scheme: .textForeground)

        contentView.addSubview(titleLabel)
    }

    private func createPlayPauseButton() {
        playPauseButton = IconButton(style: .default)
        playPauseButton.setIcon(.play, size: .tiny, for: UIControl.State.normal)

        contentView.addSubview(playPauseButton)
    }

    private func createCloseButton() {
        closeButton = IconButton(style: .default)
        closeButton.setIcon(.cross, size: .tiny, for: UIControl.State.normal)
        contentView.addSubview(closeButton)
        closeButton.accessibilityIdentifier = "mediabarCloseButton"
    }

    private func createBorderView() {
        bottomSeparatorLine = UIView()
        bottomSeparatorLine.backgroundColor = UIColor.from(scheme: .separator)

        addSubview(bottomSeparatorLine)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    override func updateConstraints() {
        super.updateConstraints()

        guard !initialConstraintsCreated else {
            return
        }

        initialConstraintsCreated = true

        let iconSize: CGFloat = 16
        let buttonInsets: CGFloat = traitCollection.horizontalSizeClass == .regular ? 32 : 16

        [contentView,
         titleLabel,
         playPauseButton,
         closeButton,
         bottomSeparatorLine].prepareForLayout()

        contentView.fitInSuperview()

        titleLabel.pinToSuperview(axisAnchor: .centerY)

        playPauseButton.setDimensions(length: iconSize)
        playPauseButton.pinToSuperview(axisAnchor: .centerY)
        playPauseButton.pinToSuperview(anchor: .leading, inset: buttonInsets)

        closeButton.setDimensions(length: iconSize)
        closeButton.pinToSuperview(axisAnchor: .centerY)
        closeButton.pinToSuperview(anchor: .trailing, inset: buttonInsets)

        titleLabel.leftAnchor.constraint(equalTo: playPauseButton.rightAnchor, constant: 8).isActive = true
        closeButton.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 8).isActive = true

        bottomSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        bottomSeparatorLine.fitInSuperview(exclude: [.top])

    }
}
