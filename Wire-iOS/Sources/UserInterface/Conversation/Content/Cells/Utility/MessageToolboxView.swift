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
    public let reactionsView = ReactionsView()
    private var tapGestureRecogniser: UITapGestureRecognizer!
    
    public weak var delegate: MessageToolboxViewDelegate?

    private var previousLayoutBounds: CGRect = CGRectZero
    
    private(set) weak var message: ZMMessage?
    public var forceShowTimestamp: Bool = false {
        didSet {
            guard let message = self.message else {
                return
            }
            self.configureForMessage(message)
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        CASStyler.defaultStyler().styleItem(self)
        
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.accessibilityIdentifier = "reactionsView"
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
        
        constrain(self, self.reactionsView, self.statusLabel) { selfView, reactionsView, statusLabel in
            statusLabel.top == selfView.top + 4
            statusLabel.left == selfView.left
            statusLabel.right <= selfView.rightMargin
            selfView.height == 20 ~ 750
            
            reactionsView.left >= statusLabel.right
            reactionsView.right == selfView.rightMargin
            reactionsView.centerY == statusLabel.centerY
        }
        
        tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(MessageToolboxView.onTapContent(_:)))
        tapGestureRecogniser.delegate = self
        
        self.addGestureRecognizer(tapGestureRecogniser)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureForMessage(message: ZMMessage) {
        self.message = message
        self.configureInfoLabel(message)
        self.configureLikedState(message)
    }
    
    private func configureLikedState(message: ZMMessage) {
        // TODO LIKE: self.likesView.reactions = message.reactions
        //self.reactionsView.likers = message.reactions
        self.reactionsView.likers = [ZMUser.selfUser(), ZMUser.selfUser(), ZMUser.selfUser(), ZMUser.selfUser()]
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
    
    private func configureInfoLabel(message: ZMMessage) {
        if !self.forceShowTimestamp { //  message.reactions.count > 0
             self.configureReactions(message)
        }
        else {
            self.configureTimestamp(message)
        }
    }
    
    private func configureReactions(message: ZMMessage) {
        let likers = [ZMUser.selfUser(), ZMUser.selfUser()] // TODO LIKE
        
        let likersNames = likers.map { user in
            return user.displayName
        }.joinWithSeparator(", ")
        
        let attributes = [NSFontAttributeName: statusLabel.font, NSForegroundColorAttributeName: statusLabel.textColor]
        
        let labelSize = (likersNames as NSString).sizeWithAttributes(attributes)
        if labelSize.width > self.bounds.size.width {
            let likersCount = String(format: "content.system.message_likes_count".localized, likers.count)
            statusLabel.attributedText = likersCount && attributes
        }
        else {
            statusLabel.attributedText = likersNames && attributes
        }
        
        statusLabel.accessibilityLabel = statusLabel.attributedText.string
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let message = self.message where CGRectEqualToRect(self.bounds, self.previousLayoutBounds) else {
            return
        }
        
        self.previousLayoutBounds = self.bounds
        
        self.configureInfoLabel(message)
    }
    
    // MARK: - Events
    
    @objc func onTapContent(button: UIButton!) {
//       TODO LIKE: if let message = self.message where message.reactions.count > 0 {
            self.delegate?.messageToolboxViewDidSelectReactions(self)
//        }
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

extension MessageToolboxView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isEqual(self.tapGestureRecogniser)
    }
}
