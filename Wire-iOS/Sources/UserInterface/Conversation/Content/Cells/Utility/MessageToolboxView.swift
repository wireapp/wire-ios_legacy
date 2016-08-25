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
import zmessaging
import Cartography
import Classy

@objc public class MessageToolboxView: UIView {
    public let timestampLabel = UILabel()
    public let likeIcon = UIImageView()
    public let likesView = LikesView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        CASStyler.defaultStyler().styleItem(self)
        
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(timestampLabel)
        
        constrain(self, self.timestampLabel) { selfView, timestampLabel in
            timestampLabel.top == selfView.top + 4
            timestampLabel.left == selfView.left
            timestampLabel.right == selfView.right
            selfView.height == 16 ~ 750
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureForMessage(message: ZMMessage) {
        self.configureTimestamp(message)
        self.configureLikedState(message)
    }
    
    private func configureLikedState(message: ZMMessage) {
        
    }
    
    private func configureTimestamp(message: ZMMessage) {
        if let systemMessage = message as? ZMSystemMessage where systemMessage.systemMessageType == .MessageDeletedForEveryone {
            timestampLabel.text = Message.formattedDeletedDateForMessage(message)
        }
        else if let _ = message.updatedAt {
            timestampLabel.text = Message.formattedEditedDateForMessage(message)
        }
        else {
            timestampLabel.text = Message.formattedReceivedDateLongVersion(message)
        }
    }
}

