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

public final class ConversationTitleView: UIView {
    
    var titleColor, titleColorSelected: UIColor?
    var titleFont: UIFont?
    var titleButton = UIButton()
    public var tapHandler: ((UIButton) -> Void)? = nil
    
    init(conversation: ZMConversation) {
        super.init(frame: CGRect.zero)
        createViews(conversation)
        CASStyler.default().styleItem(self)
        configure(conversation)
        frame = titleButton.bounds
        createConstraints()
    }
    
    private func createViews(_ conversation: ZMConversation) {
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        addSubview(titleButton)
    }
    
    func configure(_ conversation: ZMConversation) {
        guard let font = titleFont, let color = titleColor, let selectedColor = titleColorSelected else { return }
        let title = conversation.displayName.uppercased() && font
        
        let titleWithColor: (UIColor) -> NSAttributedString = {
            var attributed = (title + "  " + NSAttributedString(attachment: .downArrow(color: $0)))
            if conversation.securityLevel == .secure {
                attributed = NSAttributedString(attachment: .verifiedShield()) + "  " + attributed
            }
            return attributed && $0
        }

        titleButton.setAttributedTitle(titleWithColor(color), for: UIControlState())
        titleButton.setAttributedTitle(titleWithColor(selectedColor), for: .highlighted)
        titleButton.sizeToFit()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func createConstraints() {
        constrain(self, titleButton) { view, button in
            button.edges == view.edges
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
