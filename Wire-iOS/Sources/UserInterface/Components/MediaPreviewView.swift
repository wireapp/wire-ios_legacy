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

final class MediaPreviewView: RoundedView {

    let playButton = IconButton()
    let titleLabel = UILabel()
    let providerImageView = UIImageView()
    let previewImageView = ImageResourceView()
    let overlayView = UIView()

    weak var delegate: ContextMenuLinkViewDelegate?

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupSubviews()
        setupLayout()

        if #available(iOS 13.0, *) {
            addInteraction(UIContextMenuInteraction(delegate: self))
        }

    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        shape = .rounded(radius: 4)
        layer.masksToBounds = true

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        addSubview(previewImageView)

        overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.48)
        addSubview(overlayView)

        titleLabel.font = UIFont.normalLightFont
        titleLabel.textColor = UIColor.white
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)

        playButton.isUserInteractionEnabled = false
        playButton.setIcon(.externalLink, size: .medium, for: .normal)
        playButton.setIconColor(UIColor.white, for: UIControl.State.normal)
        addSubview(playButton)

        addSubview(providerImageView)
    }

    private func setupLayout() {
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        providerImageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // contentView
            // previewImageView
            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewImageView.topAnchor.constraint(equalTo: topAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // overlayView
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // titleLabel
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            // providerImageView
            providerImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            providerImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            // playButton
            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

}

// MARK: - UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension MediaPreviewView: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return delegate?.linkPreviewContextMenu(view: self)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            self.delegate?.linkViewWantsToOpenURL(self)
        }
    }
}
