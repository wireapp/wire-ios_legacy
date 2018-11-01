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

import Foundation
import Cartography
import TTTAttributedLabel

public final class UnknownMessageCell: CustomMessageCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.messageText = "content.system.unknown_message.body".localized
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class CustomMessageCell : ConversationCell {

    public var messageLabel : TTTAttributedLabel = TTTAttributedLabel(frame: CGRect.zero)
    var messageText: String? {
        didSet {
            messageLabel.text = messageText
            messageLabel.textTransform = .upper
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        messageLabel.extendsLinkTouchArea = true
        messageLabel.numberOfLines = 0
        messageLabel.isAccessibilityElement = true
        messageLabel.accessibilityLabel = "Text"
        messageLabel.linkAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
                                       NSAttributedString.Key.foregroundColor: ZMUser.selfUser().accentColor]

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        authorImageView.alpha = 0.5
        authorLabel.alpha = 0.5
        messageContentView.addSubview(messageLabel)

        constrain(messageLabel, messageContentView) { (messageLabel, container) in
            messageLabel.edges == container.edgesWithinMargins
        }

        

        messageLabel.delegate = self

        messageLabel.font = FontSpec(.small, .light).font
        messageLabel.textColor = UIColor.from(scheme: .textForeground)
    }

}

extension CustomMessageCell : TTTAttributedLabelDelegate {

    public func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url)
    }
}
