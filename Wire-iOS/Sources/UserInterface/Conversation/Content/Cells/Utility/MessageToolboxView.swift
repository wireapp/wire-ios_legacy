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
import WireSyncEngine

@objc public protocol MessageToolboxViewDelegate: NSObjectProtocol {
    func messageToolboxDidRequestOpeningDetails(_ messageToolboxView: MessageToolboxView, preferredDisplayMode: MessageDetailsDisplayMode)
    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectDelete(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidRequestLike(_ messageToolboxView: MessageToolboxView)
}

@objcMembers open class MessageToolboxView: UIView {
    fileprivate static let resendLink = URL(string: "settings://resend-message")!
    fileprivate static let deleteLink = URL(string: "settings://delete-message")!

    private static let ephemeralTimeFormatter = EphemeralTimeoutFormatter()

    private static let statusFont = UIFont.smallSemiboldFont
    private var statusTextColor: UIColor {
        return UIColor.from(scheme: .textDimmed)
    }

    public let statusTextView: UITextView = {
        let textView = UITextView(frame: CGRect.zero)
        textView.backgroundColor = .clear
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.isAccessibilityElement = true
        textView.accessibilityLabel = "DeliveryStatus"
        textView.textContainer.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        textView.textContainer.maximumNumberOfLines = 1
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        textView.linkTextAttributes = [.foregroundColor: UIColor.vividRed,
                                              .underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber]

        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0

        return textView
    }()

    fileprivate var tapGestureRecogniser: UITapGestureRecognizer!

    fileprivate let likeButton = LikeButton()
    fileprivate let likeButtonContainer = UIView()
    fileprivate var likeButtonWidth: NSLayoutConstraint!
    fileprivate var heightConstraint: NSLayoutConstraint!

    open weak var delegate: MessageToolboxViewDelegate?

    fileprivate var previousLayoutBounds: CGRect = CGRect.zero
    
    fileprivate(set) weak var message: ZMConversationMessage?
    
    fileprivate var forceShowTimestamp: Bool = false
    private var isConfigured: Bool = false
    
    private var timestampTimer: Timer? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
    }
    
    private func setupViews() {
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.accessibilityIdentifier = "likeButton"
        likeButton.accessibilityLabel = "likeButton"
        likeButton.addTarget(self, action: #selector(requestLike), for: .touchUpInside)
        likeButton.setIconColor(statusTextColor, for: .normal)
        likeButton.setIconColor(UIColor(for: .vividRed), for: .selected)
        likeButton.hitAreaPadding = CGSize(width: 20, height: 20)

        statusTextView.delegate = self

        [likeButtonContainer, likeButton, statusTextView].forEach(addSubview)
    }
    
    private func createConstraints() {
        likeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        statusTextView.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = heightAnchor.constraint(equalToConstant: 28)
        heightConstraint.priority = UILayoutPriority(999)

        likeButtonWidth = likeButtonContainer.widthAnchor.constraint(equalToConstant: UIView.conversationLayoutMargins.left)

        NSLayoutConstraint.activate([
            heightConstraint,

            // likeButton
            likeButtonWidth,
            likeButtonContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            likeButtonContainer.topAnchor.constraint(equalTo: topAnchor),
            likeButtonContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            likeButton.centerXAnchor.constraint(equalTo: likeButtonContainer.centerXAnchor),
            likeButton.centerYAnchor.constraint(equalTo: likeButtonContainer.centerYAnchor),

            // statusTextView align vertically center
            statusTextView.leadingAnchor.constraint(equalTo: likeButtonContainer.trailingAnchor),
            statusTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIView.conversationLayoutMargins.right),
            statusTextView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func configureForMessage(_ message: ZMConversationMessage, forceShowTimestamp: Bool, animated: Bool = false) {
        if !self.isConfigured {
            self.isConfigured = true

            setupViews()
            createConstraints()
            
            tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(MessageToolboxView.onTapContent(_:)))
            tapGestureRecogniser.delegate = self
            addGestureRecognizer(tapGestureRecogniser)
        }

        self.forceShowTimestamp = forceShowTimestamp
        self.message = message

        self.configureLikedState(message, animated: animated)
        self.layoutIfNeeded()

        if !self.forceShowTimestamp && message.hasReactions() {
            self.configureReactions(message, animated: animated)
        }
        else {
            self.configureTimestamp(message, animated: animated)
        }
    }
    
    @objc
    func startCountdownTimer() {
        stopCountdownTimer()
        
        guard let message = message, message.isEphemeral, !message.hasBeenDeleted, !message.isObfuscated else { return }
        
        timestampTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let `self` = self, let message = self.message else {
                return
            }
            self.configureTimestamp(message, animated: false)
        }
    }
    
    @objc
    func stopCountdownTimer() {
        timestampTimer?.invalidate()
        timestampTimer = nil
    }
    
    func setHidden(_ isHidden: Bool, animated: Bool) {

        let changes = {
            self.heightConstraint?.constant = isHidden ? 0 : 28
            self.alpha = isHidden ? 0 : 1
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.35) {
                changes()
            }
        } else {
            layer.removeAllAnimations()
            changes()
        }
    }

    @objc private func requestLike() {
        delegate?.messageToolboxViewDidRequestLike(self)
    }

    @objc(updateForMessage:)
    func update(for change: MessageChangeInfo) {
        if change.reactionsChanged {
            configureLikedState(change.message, animated: true)
        }
    }
    
    override open func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            stopCountdownTimer()
        }
    }
    
    fileprivate func configureLikedState(_ message: ZMConversationMessage, animated: Bool) {
        let showLikeButton: Bool

        if forceShowTimestamp {
            showLikeButton = message.canBeLiked
        } else {
            showLikeButton = message.liked || message.hasReactions()
        }

        // Prepare Animations
        let needsAnimation = animated && (showLikeButton ? likeButton.isHidden : !likeButton.isHidden)

        if showLikeButton && likeButton.isHidden {
            likeButton.alpha = 0
            likeButton.isHidden = false
        }

        let changes = {
            self.likeButton.alpha = showLikeButton ? 1 : 0
        }

        let completion: (Bool) -> Void = { _ in
            self.likeButton.isHidden = !showLikeButton
        }

        // Change State and Appearance
        likeButton.setIcon(message.liked ? .liked : .like, with: .like, for: .normal)
        likeButton.setIcon(.liked, with: .like, for: .selected)
        likeButton.setSelected(message.liked, animated: false)

        // Animate Changes
        if needsAnimation {
            UIView.animate(withDuration: 0.2, animations: changes, completion: completion)
        } else {
            changes()
            completion(true)
        }
    }
    
    fileprivate func timestampString(_ message: ZMConversationMessage) -> String? {
        let timestampString: String?

        if let editedTimeString = message.formattedEditedDate() {
            timestampString = String(format: "content.system.edited_message_prefix_timestamp".localized, editedTimeString)
        } else if let dateTimeString = message.formattedReceivedDate() {
            if let systemMessage = message as? ZMSystemMessage , systemMessage.systemMessageType == .messageDeletedForEveryone {
                timestampString = String(format: "content.system.deleted_message_prefix_timestamp".localized, dateTimeString)
            } else if let durationString = message.systemMessageData?.callDurationString() {
                timestampString = dateTimeString + " · " + durationString
            } else {
                timestampString = dateTimeString
            }
        } else {
            timestampString = .none
        }
        
        return timestampString
    }
    
    fileprivate func configureReactions(_ message: ZMConversationMessage, animated: Bool = false) {
        guard !self.bounds.equalTo(CGRect.zero) else {
            return
        }
        
        let likers = message.likers()
        
        let likersNames = likers.map { user in
            return user.displayName
            }.joined(separator: ", ")
        
        let attributes: [NSAttributedString.Key : AnyObject] = [.font: MessageToolboxView.statusFont, .foregroundColor: statusTextColor]
        let likersNamesAttributedString = likersNames && attributes

        let framesetter = CTFramesetterCreateWithAttributedString(likersNamesAttributedString)
        let targetSize = CGSize(width: 10000, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, likersNamesAttributedString.length), nil, targetSize, nil)

        let attributedText: NSAttributedString
        if labelSize.width > statusTextView.bounds.width {
            let likersCount = String(format: "participants.people.count".localized, likers.count)
            attributedText = likersCount && attributes
        }
        else {
            attributedText = likersNamesAttributedString
        }

        if let currentText = self.statusTextView.attributedText, currentText.string == attributedText.string {
            return
        }
        
        let changeBlock = {
            self.updateStatusTextView(attributedText: attributedText)
        }
        
        if animated {
            statusTextView.wr_animateSlideTo(.down, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }

    fileprivate func updateStatusTextView(attributedText: NSAttributedString) {
        statusTextView.attributedText = attributedText
        statusTextView.accessibilityValue = statusTextView.attributedText.string
    }

    fileprivate func configureTimestamp(_ message: ZMConversationMessage, animated: Bool = false) {

        guard let changeBlock = statusUpdate(message: message) else { return }

        if animated {
            statusTextView.wr_animateSlideTo(.up, newState: changeBlock)
        } else {
            changeBlock()
        }
    }

    fileprivate func selfStatusForReadDeliveryState(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let conversationType = message.conversation?.conversationType else {return nil}

        switch conversationType {
        case .group:
            let imageIcon = NSTextAttachment.textAttachment(for: .eye, with: statusTextColor)!

            let statusString: NSAttributedString

            statusString = NSAttributedString(attachment: imageIcon) + " \(message.readReceipts.count)"

            return statusString
        case .oneOnOne:
            let imageIcon = NSTextAttachment.textAttachment(for: .eye, with: statusTextColor)!

            let statusString: NSAttributedString

            if let timeString = message.readReceipts.first?.serverTimestamp {
                statusString = NSAttributedString(attachment: imageIcon) + " " + Message.formattedDate(timeString)
            } else {
                statusString = NSMutableAttributedString(attachment: imageIcon)
            }

            return statusString
        default:
            return nil
        }
    }

    fileprivate func selfStatus(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let sender = message.sender,
              sender.isSelfUser else { return nil }

        var deliveryStateString: String? = .none

        switch message.deliveryState {
        case .pending:
            deliveryStateString = "content.system.pending_message_timestamp".localized
        case .read:
            return selfStatusForReadDeliveryState(for: message)
        case .delivered:
            deliveryStateString = "content.system.message_delivered_timestamp".localized
        case .sent:
            deliveryStateString = "content.system.message_sent_timestamp".localized
        case .failedToSend:
            let resendString = NSAttributedString(string: "content.system.failedtosend_message_timestamp_resend".localized, attributes:[.link: type(of: self).resendLink])

            let deleteRange = NSAttributedString(string: "content.system.failedtosend_message_timestamp_delete".localized, attributes:[.link: type(of: self).deleteLink])

            return NSAttributedString(string:"content.system.failedtosend_message_timestamp".localized) + resendString + NSAttributedString(string:" · ") + deleteRange

        case .invalid:
            return nil
        }

        if let deliveryStateString = deliveryStateString {
            return NSAttributedString(string: deliveryStateString)
        } else {
            return nil
        }
    }


    fileprivate func statusString(for message: ZMConversationMessage) -> NSAttributedString {
        var deliveryStateString: NSAttributedString? = selfStatus(for: message)

        // Ephemeral overrides

        let showDestructionTimer = message.isEphemeral && !message.isObfuscated && nil != message.destructionDate
        if let destructionDate = message.destructionDate, showDestructionTimer {
            let remaining = destructionDate.timeIntervalSinceNow + 1 // We need to add one second to start with the correct value

            if remaining > 0 {
                if let string = MessageToolboxView.ephemeralTimeFormatter.string(from: remaining) {

                    deliveryStateString = NSMutableAttributedString(string: string)
                }
            } else if message.isAudio {
                // do nothing, audio messages are allowed to extend the timer
                // past the destruction date.
            }
        }

        // System message overrides

        let finalText: NSAttributedString

        if let childMessages = message.systemMessageData?.childMessages,
            !childMessages.isEmpty,
            let timestamp = timestampString(message) {
            let childrenTimestamps = childMessages.compactMap {
                $0 as? ZMConversationMessage
                }.sorted { left, right in
                    left.serverTimestamp < right.serverTimestamp
                }.compactMap(timestampString)

            finalText = NSAttributedString(string: childrenTimestamps.reduce(timestamp) { (text, current) in
                return "\(text)\n\(current)"
            })
        } else if let timestampString = self.timestampString(message),
            message.deliveryState.isOne(of: .delivered, .sent, .read) {
            if let deliveryStateString = deliveryStateString, Message.shouldShowDeliveryState(message) {
                finalText = NSAttributedString(string: timestampString + " ・ ") + deliveryStateString
            }
            else {
                finalText = NSMutableAttributedString(string: timestampString)
            }
        }
        else {
            finalText = (deliveryStateString ?? NSAttributedString(string: ""))
        }

        return finalText
    }

    fileprivate func statusUpdate(message: ZMConversationMessage) -> (()->())? {
        let finalText = statusString(for: message)

        if statusTextView.attributedText?.string == finalText.string {
            return nil
        }

        let attributedText = NSMutableAttributedString(attributedString: finalText && [.font: MessageToolboxView.statusFont, .foregroundColor: statusTextColor])


        if let currentText = self.statusTextView.attributedText, currentText.string == attributedText.string {
            return nil
        }

        let changeBlock =  {
            self.updateStatusTextView(attributedText: attributedText)
        }

        return changeBlock
    }
    
    fileprivate func configureLikeTip(_ message: ZMConversationMessage, animated: Bool = false) {
        let likeTooltipText = "content.system.like_tooltip".localized
        let attributes: [NSAttributedString.Key : AnyObject] = [.font: MessageToolboxView.statusFont, .foregroundColor: statusTextColor]
        let attributedText = likeTooltipText && attributes

        if let currentText = self.statusTextView.attributedText, currentText.string == attributedText.string {
            return
        }
        
        let changeBlock = {
            self.updateStatusTextView(attributedText: attributedText)
        }
        
        if animated {
            statusTextView.wr_animateSlideTo(.up, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let message = self.message, !self.bounds.equalTo(self.previousLayoutBounds) else {
            return
        }
        
        self.previousLayoutBounds = self.bounds
        
        self.configureForMessage(message, forceShowTimestamp: self.forceShowTimestamp)
    }
    
    
    // MARK: - Events

    @objc func onTapContent(_ sender: UITapGestureRecognizer!) {
        if let displayMode = preferredDetailsDisplayMode() {
            delegate?.messageToolboxDidRequestOpeningDetails(self, preferredDisplayMode: displayMode)
        }
    }

    func preferredDetailsDisplayMode() -> MessageDetailsDisplayMode? {
        if !self.forceShowTimestamp && message?.hasReactions() == true {
            return .reactions
        } else if message?.areReadReceiptsDetailsAvailable == true {
            return .receipts
        }

        return nil
    }
    
    @objc func prepareForReuse() {
        self.message = nil
    }
}

extension MessageToolboxView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isEqual(self.tapGestureRecogniser)
    }
}

extension MessageToolboxView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch URL {
        case MessageToolboxView.resendLink:
            self.delegate?.messageToolboxViewDidSelectResend(self)
        case MessageToolboxView.deleteLink:
            self.delegate?.messageToolboxViewDidSelectDelete(self)
        default:
            return false
        }
        return true
    }
}
