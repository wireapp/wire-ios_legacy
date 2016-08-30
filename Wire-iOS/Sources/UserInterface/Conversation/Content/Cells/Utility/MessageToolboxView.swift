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
import TTTAttributedLabel

extension ZMMessage {
    func formattedReceivedDate() -> String? {
        guard let timestamp = self.serverTimestamp else {
            return .None
        }
        let timeString = Message.longVersionTimeFormatter().stringFromDate(timestamp)
        let oneDayInSeconds = 24.0 * 60.0 * 60.0
        let shouldShowDate = fabs(timestamp.timeIntervalSinceReferenceDate - NSDate().timeIntervalSinceReferenceDate) > oneDayInSeconds
        
        if shouldShowDate {
            let dateString = Message.shortVersionDateFormatter().stringFromDate(timestamp)
            return dateString + " " + timeString
        }
        else {
            return timeString
        }
    }
}

@objc public protocol MessageToolboxViewDelegate: NSObjectProtocol {
    func messageToolboxViewDidSelectReactions(messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectResend(messageToolboxView: MessageToolboxView)
}

@objc public class MessageToolboxView: UIView {
    private static let resendLink = NSURL(string: "settings://resend-message")!
    
    public let statusLabel = TTTAttributedLabel(frame: CGRectZero)
    public let likeButton = IconButton()
    public let reactionsView = ReactionsView()
    //    private var tapGestureRecogniser: UITapGestureRecognizer! // TODO LIKE:
    
    public weak var delegate: MessageToolboxViewDelegate?

    override init(frame: CGRect) {
        
        super.init(frame: frame)
        CASStyler.defaultStyler().styleItem(self)
        
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.accessibilityIdentifier = "reactionsView"
        reactionsView.hidden = true // TODO LIKE:
        self.addSubview(reactionsView)
    
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.delegate = self
        statusLabel.extendsLinkTouchArea = true
        statusLabel.userInteractionEnabled = true
        statusLabel.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
        statusLabel.linkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                                      NSForegroundColorAttributeName: UIColor(forZMAccentColor: .VividRed)]
        statusLabel.activeLinkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                                            NSForegroundColorAttributeName: UIColor(forZMAccentColor: .VividRed).colorWithAlphaComponent(0.5)]
        
        self.addSubview(statusLabel)
        
        self.likeButton.translatesAutoresizingMaskIntoConstraints = false
        self.likeButton.accessibilityIdentifier = "likeButton"
        self.likeButton.addTarget(self, action: #selector(MessageToolboxView.onLikePressed(_:)), forControlEvents: .TouchUpInside)
        self.likeButton.setIcon(.Like, withSize: .MessageStatus, forState: .Normal)
        self.likeButton.setIconColor(UIColor.grayColor(), forState: .Normal)
        self.likeButton.setIcon(.Liked, withSize: .MessageStatus, forState: .Selected)
        self.likeButton.setIconColor(UIColor(forZMAccentColor: .VividRed), forState: .Selected)
        self.likeButton.hitAreaPadding = CGSizeMake(20, 20)
        self.likeButton.hidden = true // TODO LIKE:
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
        
//        TODO LIKE: tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(MessageToolboxView.onTapContent(_:)))
//        tapGestureRecogniser.delegate = self
//        
//        self.addGestureRecognizer(tapGestureRecogniser)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureForMessage(message: ZMMessage) {
        self.configureTimestamp(message)
        self.configureLikedState(message)
    }
    
    private func configureLikedState(message: ZMMessage) {
        // TODO LIKE: self.likesView.reactions = message.reactions
        //self.reactionsView.likers = message.reactions
        
        //let liked = message.isLiked
        //self.likeButton.selected = liked
    }
    
    private func timestampString(message: ZMMessage) -> String? {
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
        
        return timestampString
    }
    
    private func configureTimestamp(message: ZMMessage) {       
        var deliveryStateString: String? = .None
        
        if let sender = message.sender where sender.isSelfUser {
            switch message.deliveryState {
            case .Pending:
                deliveryStateString = "content.system.pending_message_timestamp".localized
            case .Sent:
                deliveryStateString = "content.system.message_sent_timestamp".localized
            case .Delivered:
                deliveryStateString = "content.system.message_delivered_timestamp".localized
            case .FailedToSend:
                deliveryStateString = "content.system.failedtosend_message_timestamp".localized + " " + "content.system.failedtosend_message_timestamp_resend".localized
            default:
                deliveryStateString = .None
            }
        }
    
        let finalText: String
        
        if let timestampString = self.timestampString(message) where message.deliveryState == .Delivered || message.deliveryState == .Sent {
            if let deliveryStateString = deliveryStateString {
                finalText = timestampString + " ・ " + deliveryStateString
            }
            else {
                finalText = timestampString
            }
        }
        else {
            finalText = (deliveryStateString ?? "")
        }
        
        let attributedText = NSMutableAttributedString(attributedString: finalText && [NSFontAttributeName: statusLabel.font, NSForegroundColorAttributeName: statusLabel.textColor])
        
        if message.deliveryState == .FailedToSend {
            let linkRange = (finalText as NSString).rangeOfString("content.system.failedtosend_message_timestamp_resend".localized)
            attributedText.addAttributes([NSLinkAttributeName: self.dynamicType.resendLink], range: linkRange)
        }
        statusLabel.attributedText = attributedText
        statusLabel.accessibilityLabel = statusLabel.attributedText.string
        statusLabel.addLinks()
    }
    
    // MARK: - Events
    
    @objc func onLikePressed(button: UIButton!) {
        ZMUserSession.sharedSession().performChanges {
            // message.liked = !message.liked // TODO LIKE:
        }
        
        self.likeButton.selected = !self.likeButton.selected;
    }
    
    @objc func onTapContent(button: UIButton!) {
        self.delegate?.messageToolboxViewDidSelectReactions(self)
    }
}


extension MessageToolboxView: TTTAttributedLabelDelegate {
    
    // MARK: - TTTAttributedLabelDelegate
    
    public func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL URL: NSURL!) {
        if URL.isEqual(self.dynamicType.resendLink) {
            self.delegate?.messageToolboxViewDidSelectResend(self)
        }
    }
}

// TODO LIKE: extension MessageToolboxView: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return gestureRecognizer.isEqual(self.tapGestureRecogniser)
//    }
//}
