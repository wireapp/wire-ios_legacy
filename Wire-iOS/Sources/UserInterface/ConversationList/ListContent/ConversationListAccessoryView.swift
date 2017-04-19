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
import Cartography

final internal class ConversationListAccessoryView: UIView {
    var icon: ConversationStatusIcon = .none {
        didSet {
            self.updateForIcon()
        }
    }
    
    let mediaPlaybackManager: MediaPlaybackManager
    
    let badgeView = RoundedBadge(view: UIView())
    let typingView = UIImageView()
    let textLabel = UILabel()
    let iconView = UIImageView()
    var collapseWidthConstraint: NSLayoutConstraint!
    
    init(mediaPlaybackManager: MediaPlaybackManager) {
        self.mediaPlaybackManager = mediaPlaybackManager
        super.init(frame: .zero)
        
        self.isAccessibilityElement = true
        
        textLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        textLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
        textLabel.textAlignment = .center
        
        typingView.contentMode = .center
        typingView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        typingView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
        typingView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        typingView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        
        iconView.contentMode = .center
        iconView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        iconView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
        iconView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        iconView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        
        [badgeView, typingView].forEach(addSubview)
        
        constrain(self, badgeView, typingView) { selfView, badgeView, typingView in
            badgeView.height == 20
            badgeView.edges == selfView.edges
            
            typingView.leading == selfView.leading ~ LayoutPriority(999)
            typingView.trailing == selfView.trailing ~ LayoutPriority(999)
            typingView.top == selfView.top
            typingView.bottom == selfView.bottom
            typingView.width >= 28
            
            selfView.width >= 28
            self.collapseWidthConstraint = selfView.width == 0
        }
        self.collapseWidthConstraint.isActive = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var viewForState: UIView? {
        let iconSize: CGFloat = 12
        
        switch self.icon {
        case .pendingConnection:
            iconView.image = UIImage(for: .clock, fontSize: iconSize, color: .white)
            self.accessibilityValue = "pending connection"
            return iconView
        case .activeCall(true):
            iconView.image = UIImage(for: .phone, fontSize: iconSize, color: .white)
            self.accessibilityValue = "active call"
            return iconView
        case .activeCall(false):
            textLabel.text = "conversation_list.right_accessory.join_button.title".localized.uppercased()
            self.accessibilityValue = textLabel.text
            return textLabel
        case .missedCall:
            iconView.image = UIImage(for: .endCall, fontSize: iconSize, color: .white)
            self.accessibilityValue = "missed call"
            return iconView
        case .playingMedia:
            if let mediaPlayer = self.mediaPlaybackManager.activeMediaPlayer, mediaPlayer.state == .playing {
                iconView.image = UIImage(for: .pause, fontSize: iconSize, color: .white)
                self.accessibilityValue = "pause media"
            }
            else {
                iconView.image = UIImage(for: .play, fontSize: iconSize, color: .white)
                self.accessibilityValue = "play media"
            }
            return iconView
        case .silenced:
            iconView.image = UIImage(for: .bellWithStrikethrough, fontSize: iconSize, color: .white)
            self.accessibilityValue = "silenced"
            return iconView
        case .typing:
            self.accessibilityValue = "typing"
            return .none
        case .unreadMessages(let count):
            textLabel.text = String(count)
            self.accessibilityValue = textLabel.text
            return textLabel
        case .unreadPing:
            iconView.image = UIImage(for: .ping, fontSize: iconSize, color: .white)
            self.accessibilityValue = "ping"
            return iconView
        default:
            return .none
        }
    }
    
    public func updateForIcon() {
        self.badgeView.containedView.subviews.forEach { $0.removeFromSuperview() }
        self.badgeView.backgroundColor = UIColor(white: 0, alpha: 0.16)

        self.badgeView.isHidden = false
        self.typingView.isHidden = true
        
        self.collapseWidthConstraint.isActive = false
        
        switch self.icon {
        case .none:
            self.badgeView.isHidden = true
            self.typingView.isHidden = true
            self.collapseWidthConstraint.isActive = true

            return
        case .activeCall(_):
            self.badgeView.backgroundColor = ZMAccentColor.strongLimeGreen.color
            
        case .typing:
            self.badgeView.isHidden = true
            self.typingView.isHidden = false
            self.typingView.image = UIImage(for: .pencil, fontSize: 12.0, color: .white)
        default:
            self.typingView.image = .none
        }
        
        if let view = self.viewForState {
            self.badgeView.containedView.addSubview(view)
            
            constrain(self.badgeView.containedView, view) { parentView, view in
                view.top == parentView.top
                view.bottom == parentView.bottom
                view.leading == parentView.leading + 6
                view.trailing == parentView.trailing - 6
            }
        }
    }
}
