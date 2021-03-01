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
import Cartography
import WireCommonComponents
import UIKit
import WireSystem

final class CollectionHeaderView: UICollectionReusableView {

    public var section: CollectionsSectionSet = .none {
        didSet {
            let icon: StyleKitIcon

            switch section {
            case CollectionsSectionSet.images:
                self.titleLabel.text = "collections.section.images.title".localized(uppercased: true)
                icon = .photo
            case CollectionsSectionSet.filesAndAudio:
                self.titleLabel.text = "collections.section.files.title".localized(uppercased: true)
                icon = .document
            case CollectionsSectionSet.videos:
                self.titleLabel.text = "collections.section.videos.title".localized(uppercased: true)
                icon = .movie
            case CollectionsSectionSet.links:
                self.titleLabel.text = "collections.section.links.title".localized(uppercased: true)
                icon = .link
            default: fatal("Unknown section")
            }

            self.iconImageView.setIcon(icon, size: .tiny, color: .lightGraphite)
        }
    }

    public var totalItemsCount: UInt = 0 {
        didSet {
            self.actionButton.isHidden = totalItemsCount == 0

            let totalCountText = String(format: "collections.section.all.button".localized, totalItemsCount)
            self.actionButton.setTitle(totalCountText, for: .normal)
        }
    }

    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .from(scheme: .textForeground)

        return label
    }()

    public let actionButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.strongBlue, for: .normal)
        button.titleLabel?.font = .smallSemiboldFont

        return button
    }()

    public let iconImageView = UIImageView()

    public var selectionAction: ((CollectionsSectionSet) -> Void)? = .none

    public required init(coder: NSCoder) {
        fatal("init(coder: NSCoder) is not implemented")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.titleLabel)

        self.actionButton.contentHorizontalAlignment = .right
        self.actionButton.accessibilityLabel = "open all"
        self.actionButton.addTarget(self, action: #selector(CollectionHeaderView.didSelect(_:)), for: .touchUpInside)
        self.addSubview(self.actionButton)

        self.iconImageView.contentMode = .center
        self.addSubview(self.iconImageView)

        constrain(self, self.titleLabel, self.actionButton, self.iconImageView) { selfView, titleLabel, actionButton, iconImageView in
            iconImageView.leading == selfView.leading + 16
            iconImageView.centerY == selfView.centerY
            iconImageView.width == 16
            iconImageView.height == 16

            titleLabel.leading == iconImageView.trailing + 8
            titleLabel.centerY == selfView.centerY
            titleLabel.trailing == selfView.trailing

            actionButton.leading == selfView.leading
            actionButton.top == selfView.top
            actionButton.trailing == selfView.trailing - 16
            actionButton.bottom == selfView.bottom
        }
    }

    public var desiredWidth: CGFloat = 0
    public var desiredHeight: CGFloat = 0

    override public var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: self.desiredWidth, height: self.desiredHeight)
        }
    }

    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        var newFrame = layoutAttributes.frame
        newFrame.size.width = intrinsicContentSize.width
        newFrame.size.height = intrinsicContentSize.height
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }

    @objc func didSelect(_ button: UIButton!) {
        self.selectionAction?(self.section)
    }
}
