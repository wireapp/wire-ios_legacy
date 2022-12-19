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

import UIKit
import WireCommonComponents

final class ConversationListAccessoryView: UIView {
    var icon: ConversationStatusIcon? {
        didSet {
            if icon != oldValue {
                updateForIcon()
            }

            if icon == nil {
                accessibilityValue = nil
            }
        }
    }

    var activeMediaPlayer: MediaPlayer? {
        let mediaManager = mediaPlaybackManager ?? AppDelegate.shared.mediaPlaybackManager
        return mediaManager?.activeMediaPlayer
    }

    let mediaPlaybackManager: MediaPlaybackManager?

    let badgeView = RoundedBadge(view: UIView())
    let transparentIconView = UIImageView()
    let textLabel = UILabel()
    let iconView = UIImageView()
    var collapseWidthConstraint: NSLayoutConstraint!
    var expandWidthConstraint: NSLayoutConstraint!
    var expandTransparentIconViewWidthConstraint: NSLayoutConstraint!
    let defaultViewWidth: CGFloat = 28
    let activeCallWidth: CGFloat = 20
    typealias ViewColors = SemanticColors.View
    let textLabelColor = SemanticColors.Label.textDefaultWhite

    init(mediaPlaybackManager: MediaPlaybackManager? = nil) {
        self.mediaPlaybackManager = mediaPlaybackManager
        super.init(frame: .zero)

        badgeView.accessibilityIdentifier = "action_button"
        badgeView.isAccessibilityElement = false

        textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)
        textLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        textLabel.textAlignment = .center
        textLabel.font = FontSpec.mediumSemiboldFont.font!
        textLabel.textColor = SemanticColors.Label.textDefault
        textLabel.isAccessibilityElement = false
        transparentIconView.contentMode = .center
        transparentIconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        transparentIconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        transparentIconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        transparentIconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)

        iconView.contentMode = .center
        iconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        iconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        iconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        iconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)

        [badgeView, transparentIconView].forEach(addSubview)

        createConstraints()
        updateForIcon()
    }

    private func createConstraints() {
        transparentIconView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        let transparentIconViewLeading = transparentIconView.leadingAnchor.constraint(equalTo: leadingAnchor)
        transparentIconViewLeading.priority = UILayoutPriority(999.0)

        let transparentIconViewTrailing = transparentIconView.trailingAnchor.constraint(equalTo: trailingAnchor)
        transparentIconViewTrailing.priority = UILayoutPriority(999.0)

        expandTransparentIconViewWidthConstraint = transparentIconView.widthAnchor.constraint(greaterThanOrEqualToConstant: defaultViewWidth)

        expandWidthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: defaultViewWidth)

        // collapseWidthConstraint is inactive when init, it is toggled in updateCollapseConstraints()
        collapseWidthConstraint = widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            transparentIconViewLeading,
            transparentIconViewTrailing,
            expandTransparentIconViewWidthConstraint,
            expandWidthConstraint,
            transparentIconView.topAnchor.constraint(equalTo: topAnchor),
            transparentIconView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        )
        badgeView.fitIn(view: self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var viewForState: UIView? {
        typealias ConversationsList = L10n.Accessibility.ConversationsList
        typealias ConversationListVoiceOver = L10n.Localizable.ConversationList.Voiceover.Status

        let iconSize: StyleKitIcon.Size = 12

        guard let icon = icon else { return nil }
        badgeView.backgroundColor = ViewColors.backgroundDefaultBlack
        let iconTintColor = SemanticColors.Label.textDefaultWhite

        switch icon {
        case .pendingConnection:
            iconView.setTemplateIcon(.clock, size: iconSize)
            iconView.tintColor = iconTintColor
            accessibilityValue = ConversationListVoiceOver.pendingConnection
            return iconView
        case .activeCall(false):
            accessibilityValue = ConversationListVoiceOver.activeCall
            return .none
        case .activeCall(true):
            textLabel.text = "conversation_list.right_accessory.join_button.title".localized(uppercased: true)
            textLabel.textColor = textLabelColor
            badgeView.backgroundColor = SemanticColors.Icon.backgroundJoinCall

            badgeView.isAccessibilityElement = true
            badgeView.accessibilityTraits = .button
            badgeView.accessibilityValue = ConversationsList.JoinButton.description
            badgeView.accessibilityHint = ConversationsList.JoinButton.hint
            return textLabel
        case .missedCall:
            iconView.setTemplateIcon(.endCall, size: iconSize)
            iconView.tintColor = iconTintColor
            return iconView
        case .playingMedia:
            if let mediaPlayer = activeMediaPlayer, mediaPlayer.state == .playing {
                iconView.setTemplateIcon(.pause, size: iconSize)
                iconView.tintColor = iconTintColor
                accessibilityValue = ConversationListVoiceOver.pauseMedia
            } else {
                iconView.setTemplateIcon(.play, size: iconSize)
                iconView.tintColor = iconTintColor
                accessibilityValue = ConversationListVoiceOver.playMedia
            }
            return iconView
        case .silenced:
            iconView.setTemplateIcon(.bellWithStrikethrough, size: iconSize)
            iconView.tintColor = SemanticColors.Label.textDefault
            badgeView.backgroundColor = ViewColors.backgroundDefaultWhite
            badgeView.layer.borderColor = ViewColors.borderConversationListTableViewCellBadgeReverted.cgColor
            badgeView.layer.borderWidth = 1
            badgeView.layer.cornerRadius = 6
            accessibilityValue = ConversationsList.SilencedStatus.value
            return iconView
        case .typing:
            return .none
        case .unreadMessages(let count):
            textLabel.text = String(count)
            textLabel.textColor = textLabelColor
            accessibilityValue = ConversationsList.BadgeView.value(count)
            return textLabel
        case .mention:
            iconView.setTemplateIcon(.mention, size: iconSize)
            iconView.tintColor = iconTintColor
            accessibilityValue = ConversationsList.MentionStatus.value
            return iconView
        case .reply:
            iconView.setTemplateIcon(.reply, size: iconSize)
            iconView.tintColor = iconTintColor
            accessibilityValue = ConversationsList.ReplyStatus.value
            return iconView
        case .unreadPing:
            iconView.setTemplateIcon(.ping, size: iconSize)
            iconView.tintColor = iconTintColor
            return iconView
        }
    }

    func updateCollapseConstraints(isCollapsed: Bool) {
        if isCollapsed {
            badgeView.updateCollapseConstraints(isCollapsed: isCollapsed)
            expandWidthConstraint.isActive = false
            expandTransparentIconViewWidthConstraint.isActive = false
            collapseWidthConstraint.isActive = true
        } else {
            collapseWidthConstraint.isActive = false
            expandWidthConstraint.isActive = true
            expandTransparentIconViewWidthConstraint.isActive = true
            badgeView.updateCollapseConstraints(isCollapsed: isCollapsed)
        }
    }

    func updateForIcon() {
        self.badgeView.containedView.subviews.forEach { $0.removeFromSuperview() }

        self.badgeView.isHidden = false
        self.transparentIconView.isHidden = true

        self.expandTransparentIconViewWidthConstraint.constant = defaultViewWidth
        self.expandWidthConstraint.constant = defaultViewWidth

        guard let icon = icon else {
            self.badgeView.isHidden = true
            self.transparentIconView.isHidden = true

            updateCollapseConstraints(isCollapsed: true)
            return
        }

        switch icon {
        case .activeCall(false):
            self.badgeView.isHidden = true
            self.transparentIconView.isHidden = false
            self.transparentIconView.setIcon(.phone, size: 18, color: .white)

            self.expandTransparentIconViewWidthConstraint.constant = activeCallWidth
            self.expandWidthConstraint.constant = activeCallWidth

        case .activeCall(true): // "Join" button
            self.badgeView.backgroundColor = SemanticColors.Icon.backgroundJoinCall

        case .typing:
            self.badgeView.isHidden = true
            self.transparentIconView.isHidden = false
            self.transparentIconView.setIcon(.pencil, size: 12, color: .white)

        case .unreadMessages, .mention:
            self.textLabel.textColor = textLabelColor
            self.badgeView.backgroundColor = ViewColors.backgroundDefaultBlack

        case .unreadPing, .reply, .missedCall:
            self.badgeView.backgroundColor = ViewColors.backgroundDefaultBlack

        default:
            self.transparentIconView.image = .none
        }

        updateCollapseConstraints(isCollapsed: false)

        if let view = self.viewForState {
            self.badgeView.containedView.addSubview(view)

            let parentView = self.badgeView.containedView
            view.translatesAutoresizingMaskIntoConstraints = false
            parentView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: parentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 6),
                view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -6)
            ])

        }
    }
}
