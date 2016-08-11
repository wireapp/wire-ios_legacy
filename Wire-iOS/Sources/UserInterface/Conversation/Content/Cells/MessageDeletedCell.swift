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


class MessageDeletedCell: ConversationCell {
    
    let trashImageView = UIImageView()
    let timestampView = MessageTimestampView()
    
    var trashColor: UIColor?
    var timestampHeightConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        CASStyler.defaultStyler().styleItem(self)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        trashImageView.image = trashColor.map {
            UIImage(forIcon: .Trash, iconSize: .MessageStatus, color: $0)
        }
        contentView.addSubview(trashImageView)
        messageContentView.addSubview(timestampView)
    }
    
    func createConstraints() {
        constrain(authorLabel, trashImageView, timestampView, messageContentView) { authorLabel, imageView, timestamp, messageContent in
            imageView.centerY == authorLabel.centerY
            imageView.left == authorLabel.right + 8
            timestamp.right == messageContent.rightMargin
            timestamp.left == messageContent.leftMargin
            timestamp.bottom == messageContent.bottom
            timestamp.top == messageContent.top
            timestampHeightConstraint = timestamp.height == 0 ~ 750
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        timestampHeightConstraint?.active = !selected
        UIView.animateWithDuration(0.35) { 
            self.timestampView.alpha = selected ? 1 : 0
        }
    }
    
    override func configureForMessage(message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        timestampView.timestampLabel.text = Message.formattedDeletedDateForMessage(message)
    }

}
