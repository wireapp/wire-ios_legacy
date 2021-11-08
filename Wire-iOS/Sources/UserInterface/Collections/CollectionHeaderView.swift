//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireCommonComponents
import UIKit
import WireSystem

final class CollectionHeaderView: UICollectionReusableView {

    var section: CollectionsSectionSet = .none {
        didSet {
            let icon: StyleKitIcon

            switch section {
            case CollectionsSectionSet.images:
                titleLabel.text = "collections.section.images.title".localized(uppercased: true)
                icon = .photo
            case CollectionsSectionSet.filesAndAudio:
                titleLabel.text = "collections.section.files.title".localized(uppercased: true)
                icon = .document
            case CollectionsSectionSet.videos:
                titleLabel.text = "collections.section.videos.title".localized(uppercased: true)
                icon = .movie
            case CollectionsSectionSet.links:
                titleLabel.text = "collections.section.links.title".localized(uppercased: true)
                icon = .link
            default: fatal("Unknown section")
            }

            iconImageView.setIcon(icon, size: .tiny, color: .lightGraphite)
        }
    }

    var totalItemsCount: UInt = 0 {
        didSet {
            actionButton.isHidden = totalItemsCount == 0

            let totalCountText = String(format: "collections.section.all.button".localized, totalItemsCount)
            actionButton.setTitle(totalCountText, for: .normal)
        }
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .from(scheme: .textForeground)

        return label
    }()

    let actionButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.strongBlue, for: .normal)
        button.titleLabel?.font = .smallSemiboldFont

        return button
    }()

    let iconImageView = UIImageView()

    var selectionAction: ((CollectionsSectionSet) -> Void)? = .none

    required init(coder: NSCoder) {
        fatal("init(coder: NSCoder) is not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)

        actionButton.contentHorizontalAlignment = .right
        actionButton.accessibilityLabel = "open all"
        actionButton.addTarget(self, action: #selector(CollectionHeaderView.didSelect(_:)), for: .touchUpInside)
        addSubview(actionButton)

        iconImageView.contentMode = .center
        addSubview(iconImageView)

        [titleLabel, actionButton, iconImageView].prepareForLayout()
        NSLayoutConstraint.activate([
          iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
          iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
          iconImageView.widthAnchor.constraint(equalToConstant: 16),
          iconImageView.heightAnchor.constraint(equalToConstant: 16),

          titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
          titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
          titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

          actionButton.leadingAnchor.constraint(equalTo: leadingAnchor),
          actionButton.topAnchor.constraint(equalTo: topAnchor),
          actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
          actionButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    var desiredWidth: CGFloat = 0
    var desiredHeight: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        return CGSize(width: desiredWidth, height: desiredHeight)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        var newFrame = layoutAttributes.frame
        newFrame.size.width = intrinsicContentSize.width
        newFrame.size.height = intrinsicContentSize.height
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }

    @objc func didSelect(_ button: UIButton!) {
        selectionAction?(section)
    }
}
