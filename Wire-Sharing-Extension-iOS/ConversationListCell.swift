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
import zshare
import WireExtensionComponents



class ConversationListCell: UITableViewCell {
    
    var conversation: Conversation! {
        didSet {
            if let conversation = self.conversation {
                let displayName = conversation.displayName
                self.conversationNameLabel.text = displayName;
                
                if conversation.archived! {
                    self.cas_styleClass = "archived"
                } else {
                    self.cas_styleClass = "unarchived"
                }
                
                switch (conversation.type!) {
                case .OneOnOne :
                    self.conversationAvatarView.cas_styleClass = "one-on-one"
                    var color: UIColor! = nil
                    if let accentColor = conversation.connectedUser?.accentColor {
                        color = UIColor.colorForZMColor(accentColor)
                    } else {
                        color = UIColor.accentColor
                    }
                    self.conversationAvatarView.borderColor = color
                    self.conversationAvatarView.containerView.backgroundColor = color
                case .Group:
                    self.conversationAvatarView.cas_styleClass = "group"
                }
            }
        }
    }
    
    var conversationImage: UIImage? {
        didSet {
            if let image = self.conversationImage {
                self.conversationAvatarView.imageView.image = image
                self.conversationAvatarView.initials.text = nil
            } else {
                self.conversationAvatarView.initials.text = self.conversation.connectedUser?.initials
                self.conversationAvatarView.imageView.image = nil
            }
        }
    }

    @IBOutlet fileprivate weak var conversationNameLabel: UILabel!
    @IBOutlet fileprivate weak var conversationAvatarView: AvatarImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
