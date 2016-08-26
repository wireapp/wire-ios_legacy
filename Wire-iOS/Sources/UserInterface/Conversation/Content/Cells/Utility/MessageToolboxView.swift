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

extension ZMMessage {
    func formattedReceivedDate() -> String? {
        guard let timestamp = self.serverTimestamp else {
            return .None
        }
//        let dateString = Message.longVersionDateFormatter().stringFromDate(timestamp)
        let timeString = Message.longVersionTimeFormatter().stringFromDate(timestamp)
        
        return /*dateString + " " + */timeString
    }
}

@objc public protocol MessageToolboxViewDelegate: NSObjectProtocol {
    func messageToolboxViewDidSelectReactions(messageToolboxView: MessageToolboxView)
}

@objc public class MessageToolboxView: UIView {
    public let statusLabel = UILabel()
    public let likeButton = IconButton()
    public let reactionsView = ReactionsView()
    
    public weak var delegate: MessageToolboxViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        CASStyler.defaultStyler().styleItem(self)
        
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.accessibilityIdentifier = "reactionsView"
        self.addSubview(reactionsView)
    
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.accessibilityIdentifier = "statusLabel"
        self.addSubview(statusLabel)
        
        self.likeButton.translatesAutoresizingMaskIntoConstraints = false
        self.likeButton.accessibilityIdentifier = "likeButton"
        self.likeButton.addTarget(self, action: #selector(MessageToolboxView.onLikePressed(_:)), forControlEvents: .TouchUpInside)
        self.likeButton.setIcon(.Like, withSize: .MessageStatus, forState: .Normal)
        self.likeButton.setIconColor(UIColor.grayColor(), forState: .Normal)
        self.likeButton.setIcon(.Liked, withSize: .MessageStatus, forState: .Selected)
        self.likeButton.setIconColor(UIColor(forZMAccentColor: .VividRed), forState: .Selected)
        self.likeButton.hitAreaPadding = CGSizeMake(20, 20);
        self.addSubview(self.likeButton)
        
        constrain(self, self.reactionsView, self.statusLabel, self.likeButton) { selfView, reactionsView, statusLabel, likeButton in
            statusLabel.top == selfView.top + 4
            statusLabel.left == selfView.leftMargin
            statusLabel.right == selfView.rightMargin
            selfView.height == 20 ~ 750
            
            reactionsView.right == selfView.rightMargin
            reactionsView.centerY == selfView.centerY
            
            likeButton.left == selfView.left
            likeButton.right == selfView.leftMargin
            likeButton.centerY == selfView.centerY
        }
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(MessageToolboxView.onTapContent(_:)))
        self.addGestureRecognizer(tapGestureRecogniser)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureForMessage(message: ZMMessage) {
        self.configureTimestamp(message)
        self.configureLikedState(message)
    }
    
    private func configureLikedState(message: ZMMessage) {
//        self.likesView.likers = message.likers
        self.reactionsView.likers = [ZMUser.selfUser(), ZMUser.selfUser(), ZMUser.selfUser(), ZMUser.selfUser()]
        
        let liked = false // message.isLiked
        self.likeButton.selected = liked
    }
    
    private func configureTimestamp(message: ZMMessage) {
        let timestampString: String?
        
        if let dateTimeString = message.formattedReceivedDate() {
            if let systemMessage = message as? ZMSystemMessage where systemMessage.systemMessageType == .MessageDeletedForEveryone {
                timestampString = String(format: "content.system.deleted_message_prefix_timestamp".localized, dateTimeString)
            }
            else if let _ = message.updatedAt {
                timestampString = String(format: "content.system.edited_message_prefix_timestamp".localized, dateTimeString)
            }
            else {
                timestampString = dateTimeString
            }
        }
        else {
            timestampString = .None
        }
        
        var deliveryStateString: String? = .None
        
        switch message.deliveryState {
        case .Delivered:
            deliveryStateString = "content.system.message_sent_timestamp".localized
        case .FailedToSend:
            deliveryStateString = "content.system.failedtosend_message_timestamp".localized
        case .Pending:
            deliveryStateString = "content.system.pending_message_timestamp".localized
        default:
            deliveryStateString = .None
        }
        
        if let timestampString = timestampString {
            statusLabel.text = timestampString + " • " + (deliveryStateString ?? "")
        }
        else {
            statusLabel.text = (deliveryStateString ?? "")
        }
    }
    
//    public override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
//        return CGRectContainsPoint(CGRectInset(self.bounds, 0, 20), point)
//    }
    
    // MARK: - Events
    
    @objc func onLikePressed(button: UIButton!) {
        ZMUserSession.sharedSession().performChanges {
            // message.liked = !message.liked
        }
        
        self.likeButton.selected = !self.likeButton.selected;
    }
    
    @objc func onTapContent(button: UIButton!) {
        self.delegate?.messageToolboxViewDidSelectReactions(self)
    }
    
}

