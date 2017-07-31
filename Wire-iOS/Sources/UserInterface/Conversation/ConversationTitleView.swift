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


import UIKit
import Cartography
import Classy

public final class ConversationTitleView: UIView {
    
    var titleColor, titleColorSelected: UIColor?
    var titleFont: UIFont?
    let titleButton = UIButton()
    public var tapHandler: ((UIButton) -> Void)? = nil
    
    init(conversation: ZMConversation, interactive: Bool = true) {
        super.init(frame: CGRect.zero)
        self.isAccessibilityElement = true
        self.accessibilityLabel = conversation.displayName
        self.accessibilityIdentifier = "Name"
        createViews(conversation)
        CASStyler.default().styleItem(self)

        // The attachments contain images which break the centering of the text inside the button.
        // If there is an attachment in the text we need to adjust the constraints accordingly.
        let hasAttachment = configure(conversation, interactive: interactive)
        frame = titleButton.bounds
        createConstraints(hasAttachment)
    }
    
    private func createViews(_ conversation: ZMConversation) {
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        addSubview(titleButton)
    }

    /// Configures the title view for the given conversation
    /// - parameter conversation: The conversation for which the view should be configured
    /// - parameter interactive: Whether the view should react to user interaction events
    /// - return: Whether the view contains any `NSTextAttachments`
    private func configure(_ conversation: ZMConversation, interactive: Bool) -> Bool {
        guard let font = titleFont, let color = titleColor, let selectedColor = titleColorSelected else { return false }
        let title = conversation.displayName.uppercased() && font
        let tappable = interactive && conversation.relatedConnectionState != .sent
        var hasAttachment = false

        let titleWithColor: (UIColor) -> NSAttributedString = {
            var attributed = title

            if tappable {
                attributed += "  " + NSAttributedString(attachment: .downArrow(color: $0))
                hasAttachment = true
            }
            if conversation.securityLevel == .secure {
                attributed = NSAttributedString(attachment: .verifiedShield()) + "  " + attributed
                hasAttachment = true
            }
            return attributed && $0
        }

        titleButton.setAttributedTitle(titleWithColor(color), for: UIControlState())
        titleButton.setAttributedTitle(titleWithColor(selectedColor), for: .highlighted)
        titleButton.sizeToFit()
        titleButton.isEnabled = tappable
        updateAccessibilityValue(conversation)
        setNeedsLayout()
        layoutIfNeeded()

        return hasAttachment
    }
    
    private func updateAccessibilityValue(_ conversation: ZMConversation) {
        if conversation.securityLevel == .secure {
            self.accessibilityLabel = conversation.displayName.uppercased() + ", " + "conversation.voiceover.verified".localized
        } else {
            self.accessibilityLabel = conversation.displayName.uppercased()
        }
    }
    
    private func createConstraints(_ hasAttachment: Bool) {
        constrain(self, titleButton) { view, button in
            button.leading == view.leading
            button.trailing == view.trailing
            button.top == view.top
            button.bottom == view.bottom - (hasAttachment ? 4 : 0)
        }
    }
    
    func titleButtonTapped(_ sender: UIButton) {
        tapHandler?(sender)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

fileprivate extension NSTextAttachment {

    static func downArrow(color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(for: .downArrow, fontSize: 8, color: color)
        return attachment
    }

    static func verifiedShield() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let shield = WireStyleKit.imageOfShieldverified()!
        attachment.image = shield
        let ratio = shield.size.width / shield.size.height
        let height: CGFloat = 12
        attachment.bounds = CGRect(x: 0, y: -2, width: height * ratio, height: height)
        return attachment
    }
}
