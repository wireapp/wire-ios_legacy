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

@objcMembers final class ConversationListAccessoryView: UIView {
    var icon: ConversationStatusIcon = .none {
        didSet {
            self.updateForIcon()
        }
    }
    
    let mediaPlaybackManager: MediaPlaybackManager
    
    let badgeView = RoundedBadge(view: UIView())
    let transparentIconView = UIImageView()
    let textLabel = UILabel()
    let iconView = UIImageView()
    var collapseWidthConstraint: NSLayoutConstraint!
    var expandWidthConstraint: NSLayoutConstraint!
    var expandTransparentIconViewWidthConstraint: NSLayoutConstraint!
    let defaultViewWidth: CGFloat = 28
    let activeCallWidth: CGFloat = 20
    
    @objc init(mediaPlaybackManager: MediaPlaybackManager) {
        self.mediaPlaybackManager = mediaPlaybackManager
        super.init(frame: .zero)
        
        self.isAccessibilityElement = true
        
        textLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)
        textLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        textLabel.textAlignment = .center
        textLabel.font = FontSpec(.medium, .semibold).font!
        
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
    }

    func createConstraints() {
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
            expandWidthConstraint
            ] +
            badgeView.edgesToSuperviewEdges() +
            transparentIconView.topAndBottomEdgesToSuperviewEdges()
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var viewForState: UIView? {
        let iconSize: CGFloat = 12
        
        switch self.icon {
        case .pendingConnection:
            iconView.image = UIImage(for: .clock, fontSize: iconSize, color: .white)
            accessibilityValue = "conversation_list.voiceover.status.pending_connection".localized
            return iconView
        case .activeCall(false):
            accessibilityValue = "conversation_list.voiceover.status.active_call".localized
            return .none
        case .activeCall(true):
            textLabel.text = "conversation_list.right_accessory.join_button.title".localized.uppercased()
            accessibilityValue = textLabel.text
            return textLabel
        case .missedCall:
            iconView.image = UIImage(for: .endCall, fontSize: iconSize, color: .black)
            accessibilityValue = "conversation_list.voiceover.status.missed_call".localized
            return iconView
        case .playingMedia:
            if let mediaPlayer = self.mediaPlaybackManager.activeMediaPlayer, mediaPlayer.state == .playing {
                iconView.image = UIImage(for: .pause, fontSize: iconSize, color: .white)
                accessibilityValue = "conversation_list.voiceover.status.pause_media".localized
            }
            else {
                iconView.image = UIImage(for: .play, fontSize: iconSize, color: .white)
                accessibilityValue = "conversation_list.voiceover.status.play_media".localized
            }
            return iconView
        case .silenced:
            iconView.image = UIImage(for: .bellWithStrikethrough, fontSize: iconSize, color: .white)
            accessibilityValue = "conversation_list.voiceover.status.silenced".localized
            return iconView
        case .typing:
            accessibilityValue = "conversation_list.voiceover.status.typing".localized
            return .none
        case .unreadMessages(let count):
            textLabel.text = String(count)
            accessibilityValue = textLabel.text
            return textLabel
        case .mention:
            iconView.image = UIImage(for: .mention, fontSize: iconSize, color: .black)
            accessibilityValue = "conversation_list.voiceover.status.mention".localized
            return iconView
        case .reply:
            iconView.image = UIImage(for: .reply, fontSize: iconSize, color: .black)
            accessibilityValue = "conversation_list.voiceover.status.reply".localized
            return iconView
        case .unreadPing:
            iconView.image = UIImage(for: .ping, fontSize: iconSize, color: .black)
            accessibilityValue = "conversation_list.voiceover.status.ping".localized
            return iconView
        default:
            return .none
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
    
    public func updateForIcon() {
        self.badgeView.containedView.subviews.forEach { $0.removeFromSuperview() }
        self.badgeView.backgroundColor = UIColor(white: 0, alpha: 0.16)

        self.badgeView.isHidden = false
        self.transparentIconView.isHidden = true
        
        self.expandTransparentIconViewWidthConstraint.constant = defaultViewWidth
        self.expandWidthConstraint.constant = defaultViewWidth
        
        self.textLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        
        switch self.icon {
        case .none:
            self.badgeView.isHidden = true
            self.transparentIconView.isHidden = true

            updateCollapseConstraints(isCollapsed: true)

            return
        case .activeCall(false):
            self.badgeView.isHidden = true
            self.transparentIconView.isHidden = false
            self.transparentIconView.image = UIImage(for: .phone, fontSize: 18.0, color: .white)
            
            self.expandTransparentIconViewWidthConstraint.constant = activeCallWidth
            self.expandWidthConstraint.constant = activeCallWidth

        case .activeCall(true): // "Join" button
            self.badgeView.backgroundColor = .strongLimeGreen
            
        case .typing:
            self.badgeView.isHidden = true
            self.transparentIconView.isHidden = false
            self.transparentIconView.image = UIImage(for: .pencil, fontSize: 12.0, color: .white)
            
        case .unreadMessages(_), .mention:
            self.textLabel.textColor = UIColor.from(scheme: .textForeground, variant: .light)
            self.badgeView.backgroundColor = UIColor.from(scheme: .textBackground, variant: .light)
            
        case .unreadPing,
             .reply,
             .missedCall:

            self.badgeView.backgroundColor = .from(scheme: .textBackground, variant: .light)

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
