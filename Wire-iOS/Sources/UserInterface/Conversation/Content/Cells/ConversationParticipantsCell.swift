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
import Cartography

open class ConversationParticipantsCell : ConversationCell {

    fileprivate let participantsChangedView = ParticipantsChangedView()
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style:style , reuseIdentifier:reuseIdentifier)
        
        self.messageContentView.preservesSuperviewLayoutMargins = false
        self.messageContentView.layoutMargins = UIEdgeInsetsMake(0, CGFloat(WAZUIMagic.float(forIdentifier: "content.system_message.left_margin")), 0, CGFloat(WAZUIMagic.floatForIdentifier("content.system_message.right_margin")))
        self.participantsChangedView.translatesAutoresizingMaskIntoConstraints = false
        self.messageContentView.addSubview(self.participantsChangedView)
        self.createConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) Not implemented")
    }

    fileprivate func createConstraints()
    {
        constrain(self.messageContentView, self.participantsChangedView) { contentView, participantsView in
            participantsView.edges == contentView.edges
        }
    }

    open override func configure(for message: ZMConversationMessage, layoutProperties:ConversationCellLayoutProperties)
    {
        super.configure(for: message, layoutProperties: layoutProperties)
        
        if let systemMessage = message.systemMessageData as? ZMSystemMessage {
            
            switch systemMessage.systemMessageType {
            case .participantsAdded:
                participantsChangedView.action = .added
            case .participantsRemoved:
                participantsChangedView.action = .removed
            default:
                participantsChangedView.action = .started
            }
            
            if let sender = systemMessage.sender {
                self.participantsChangedView.userPerformingAction = sender
            }
            self.participantsChangedView.participants = Array(systemMessage.users)
        }
    }
}
