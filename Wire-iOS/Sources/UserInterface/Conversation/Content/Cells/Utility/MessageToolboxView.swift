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

extension ZMConversationMessage {
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
    func messageToolboxViewDidSelectLikers(messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectResend(messageToolboxView: MessageToolboxView)
}

@objc public class MessageToolboxView: UIView {
    private static let resendLink = NSURL(string: "settings://resend-message")!
    
    public let statusLabel = TTTAttributedLabel(frame: CGRectZero)
    public let reactionsView = ReactionsView()
    private let labelClipView = UIView()
    private var tapGestureRecogniser: UITapGestureRecognizer!
    public let likeTooltipArrow = UILabel()
    
    public weak var delegate: MessageToolboxViewDelegate?

    private var previousLayoutBounds: CGRect = CGRectZero
    
    private(set) weak var message: ZMConversationMessage?
    
    private var forceShowTimestamp: Bool = false
    
    @objc public func setForceShowTimestamp(forceShowTimestamp: Bool, animated: Bool) {
        guard let message = self.message else {
            return
        }
        self.forceShowTimestamp = forceShowTimestamp
        self.configureForMessage(message, animated: animated)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        CASStyler.defaultStyler().styleItem(self)
        
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.accessibilityIdentifier = "reactionsView"
        self.addSubview(reactionsView)
    
        labelClipView.clipsToBounds = true
        labelClipView.isAccessibilityElement = true
        labelClipView.translatesAutoresizingMaskIntoConstraints = false
        labelClipView.userInteractionEnabled = true
        self.addSubview(labelClipView)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.delegate = self
        statusLabel.extendsLinkTouchArea = true
        statusLabel.userInteractionEnabled = true
        statusLabel.verticalAlignment = .Center
        statusLabel.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
        statusLabel.linkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                                      NSForegroundColorAttributeName: UIColor(forZMAccentColor: .VividRed)]
        statusLabel.activeLinkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                                            NSForegroundColorAttributeName: UIColor(forZMAccentColor: .VividRed).colorWithAlphaComponent(0.5)]
        labelClipView.addSubview(statusLabel)
        
        likeTooltipArrow.translatesAutoresizingMaskIntoConstraints = false
        likeTooltipArrow.accessibilityIdentifier = "likeTooltipArrow"
        likeTooltipArrow.text = "←"
        self.addSubview(likeTooltipArrow)
        
        constrain(self, self.reactionsView, self.statusLabel, self.labelClipView, self.likeTooltipArrow) { selfView, reactionsView, statusLabel, labelClipView, likeTooltipArrow in
            labelClipView.left == selfView.leftMargin
            labelClipView.centerY == selfView.centerY
            labelClipView.right == selfView.rightMargin
            
            statusLabel.edges == labelClipView.edges
            
            reactionsView.right == selfView.rightMargin
            reactionsView.centerY == selfView.centerY
            
            likeTooltipArrow.centerY == statusLabel.centerY
            likeTooltipArrow.right == selfView.leftMargin - 8
        }
        
        tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(MessageToolboxView.onTapContent(_:)))
        tapGestureRecogniser.delegate = self
        
        self.addGestureRecognizer(tapGestureRecogniser)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, 28)
    }
    
    public func configureForMessage(message: ZMConversationMessage, animated: Bool = false) {
        self.message = message
        
        // Show like tip
        if let sender = message.sender where !Settings.sharedSettings().likeTutorialCompleted && !sender.isSelfUser && !message.hasReactions() {
            self.reactionsView.hidden = !message.hasReactions()
            self.likeTooltipArrow.hidden = false
            self.tapGestureRecogniser.enabled = message.hasReactions()
            self.configureLikeTip(message, animated: animated)
        }
        else {
            self.likeTooltipArrow.hidden = true
            if !self.forceShowTimestamp && message.hasReactions() {
                self.reactionsView.hidden = false
                self.configureLikedState(message)
                self.layoutIfNeeded()
                self.configureReactions(message, animated: animated)
                self.tapGestureRecogniser.enabled = true
            }
            else {
                self.reactionsView.hidden = true
                self.layoutIfNeeded()
                self.configureTimestamp(message, animated: animated)
                self.tapGestureRecogniser.enabled = false
            }
        }
    }
    
    private func configureLikedState(message: ZMConversationMessage) {
        self.reactionsView.likers = message.likers()
    }
    
    private func timestampString(message: ZMConversationMessage) -> String? {
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
    
    private func configureReactions(message: ZMConversationMessage, animated: Bool = false) {
        guard !CGRectEqualToRect(self.bounds, CGRectZero) else {
            return
        }
        
        let likers = message.likers()
        
        let likersNames = likers.map { user in
            return user.displayName
        }.joinWithSeparator(", ")
        
        let attributes = [NSFontAttributeName: statusLabel.font, NSForegroundColorAttributeName: statusLabel.textColor]
        let likersNamesAttributedString = likersNames && attributes

        let framesetter = CTFramesetterCreateWithAttributedString(likersNamesAttributedString)
        let targetSize = CGSizeMake(10000, CGFloat.max)
        let labelSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, likersNamesAttributedString.length), nil, targetSize, nil)
        
        let attributedText: NSAttributedString
        
        if labelSize.width > self.statusLabel.bounds.size.width - self.reactionsView.bounds.size.width {
            let likersCount = String(format: "participants.people.count".localized, likers.count)
            attributedText = likersCount && attributes
        }
        else {
            attributedText = likersNamesAttributedString
        }

        if let currentText = self.statusLabel.attributedText where currentText.string == attributedText.string {
            return
        }
        
        let changeBlock = {
            self.statusLabel.attributedText = attributedText
            self.statusLabel.accessibilityLabel = self.statusLabel.attributedText.string
        }
        
        if animated {
            statusLabel.wr_animateSlideTo(.Down, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }
    
    private func configureTimestamp(message: ZMConversationMessage, animated: Bool = false) {
        var deliveryStateString: String? = .None
        
        if let sender = message.sender where sender.isSelfUser {
            switch message.deliveryState {
            case .Pending:
                deliveryStateString = "content.system.pending_message_timestamp".localized
            case .Delivered:
                // Code disabled until the majority would send the delivery receipts
                // deliveryStateString = "content.system.message_delivered_timestamp".localized
                fallthrough
            case .Sent:
                deliveryStateString = "content.system.message_sent_timestamp".localized
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
        
        if let currentText = self.statusLabel.attributedText where currentText.string == attributedText.string {
            return
        }
        
        let changeBlock =  {
            self.statusLabel.attributedText = attributedText
            self.statusLabel.accessibilityLabel = self.statusLabel.attributedText.string
            self.statusLabel.addLinks()
        }
        
        if animated {
            statusLabel.wr_animateSlideTo(.Up, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }
    
    private func configureLikeTip(message: ZMConversationMessage, animated: Bool = false) {
        let likeTooltipText = "content.system.like_tooltip".localized
        let attributes = [NSFontAttributeName: statusLabel.font, NSForegroundColorAttributeName: statusLabel.textColor]
        let attributedText = likeTooltipText && attributes

        if let currentText = self.statusLabel.attributedText where currentText.string == attributedText.string {
            return
        }
        
        let changeBlock =  {
            self.statusLabel.attributedText = attributedText
            self.statusLabel.accessibilityLabel = self.statusLabel.attributedText.string
        }
        
        if animated {
            statusLabel.wr_animateSlideTo(.Up, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let message = self.message where !CGRectEqualToRect(self.bounds, self.previousLayoutBounds) else {
            return
        }
        
        self.previousLayoutBounds = self.bounds
        
        self.configureForMessage(message)
    }
    
    
    // MARK: - Events

    @objc func onTapContent(sender: UITapGestureRecognizer!) {
        guard !forceShowTimestamp else { return }
        if let message = self.message where !message.likers().isEmpty {
            self.delegate?.messageToolboxViewDidSelectLikers(self)
        }
    }
    
    @objc func prepareForReuse() {
        self.message = nil
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
