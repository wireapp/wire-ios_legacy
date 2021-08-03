//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit
import WireCommonComponents

class BaseMessageRestrictionView: UIView {

    // MARK: - Properties

    let topLabel = UILabel()
    let bottomLabel = UILabel()
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()

    private var context: MessageRestrictionContext {
        didSet {
            configure()
        }
    }

    /// For the search screen
    private var isShortVersion: Bool
    let viewMargin: CGFloat

    // MARK: - Life cycle

    init(context: MessageRestrictionContext, isShortVersion: Bool = false) {
        self.context = context
        self.isShortVersion = isShortVersion
        viewMargin = isShortVersion ? 0 : 12
        super.init(frame: .zero)

        setupViews()
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    // MARK: - Helpers

    private func setupViews() {
        backgroundColor = .from(scheme: .placeholderBackground)
        setupLabels()
        setupIconView()

        var allViews: [UIView] {
            switch context {
            case .audio:
                return [topLabel, bottomLabel, iconView]
            case .video, .image:
                return [topLabel, iconView]
            }
        }
        allViews.forEach(self.addSubview)
    }

    private func setupLabels() {
        switch context {
        case .image, .video:
            topLabel.isHidden = isShortVersion
        default:
            topLabel.isHidden = false
        }
        topLabel.numberOfLines = 1
        topLabel.lineBreakMode = .byTruncatingMiddle
        topLabel.accessibilityIdentifier = "\(context.rawValue.capitalizingFirstLetter()) + MessageRestrictionTopLabel"

        bottomLabel.numberOfLines = 1
        bottomLabel.accessibilityIdentifier = "\(context.rawValue.capitalizingFirstLetter()) + MessageRestrictionBottomLabel"
    }

    private func setupIconView() {
        iconView.contentMode = .center
        iconView.accessibilityIdentifier = "\(context.rawValue.capitalizingFirstLetter()) + MessageRestrictionIcon"

        switch context {
        case .video:
            iconView.clipsToBounds = true
            iconView.layer.cornerRadius = 16
            iconView.backgroundColor = .white
        default:
            break
        }
    }

    /// Override this method to provide a different view.
    func createConstraints() {
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Public

    func configure() {
        iconView.setTemplateIcon(context.icon, size: context.iconSize)

        let titleString = context.title.localizedUppercase && .smallSemiboldFont && .from(scheme: .textForeground)
        let subtitleString = context.subtitle.localizedUppercase && .smallLightFont && .from(scheme: .textDimmed)

        switch context {
        case .audio:
            topLabel.attributedText = titleString
            bottomLabel.attributedText = subtitleString
        case .video, .image:
            topLabel.attributedText = subtitleString
        }
    }

}

enum MessageRestrictionContext: String {
    case audio
    case video
    case image

    var icon: StyleKitIcon {
        switch self {
        case .audio:
            return .microphone
        case .video:
            return .play
        case .image:
            return .photo
        }
    }

    var iconSize: StyleKitIcon.Size {
        switch self {
        case .audio:
            return .small
        case .video, .image:
            return .tiny
        }
    }

    var title: String {
        typealias MessagePreview = L10n.Localizable.Conversation.InputBar.MessagePreview
        switch self {
        case .audio:
            return MessagePreview.audio
        case .video:
            return MessagePreview.video
        case .image:
            return MessagePreview.image
        }
    }

    var subtitle: String {
        typealias FileSharingRestrictions = L10n.Localizable.FeatureConfig.FileSharingRestrictions
        switch self {
        case .audio:
            return FileSharingRestrictions.audio
        case .video:
            return FileSharingRestrictions.video
        case .image:
            return FileSharingRestrictions.picture
        }
    }
}
