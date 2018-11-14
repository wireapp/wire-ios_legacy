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
import TTTAttributedLabel

@objc public protocol MessageToolboxViewDelegate: NSObjectProtocol {
    func messageToolboxViewDidSelectLikers(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectDelete(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidRequestLike(_ messageToolboxView: MessageToolboxView)
}

@objcMembers open class MessageToolboxView: UIView {
    fileprivate static let resendLink = URL(string: "settings://resend-message")!
    fileprivate static let deleteLink = URL(string: "settings://delete-message")!

    private static let ephemeralTimeFormatter = EphemeralTimeoutFormatter()

    public let statusLabel: TTTAttributedLabel = {
        let attributedLabel = TTTAttributedLabel(frame: CGRect.zero)
        attributedLabel.font = UIFont.smallSemiboldFont
        attributedLabel.backgroundColor = .clear
        attributedLabel.textColor = UIColor.from(scheme: .textDimmed)
        attributedLabel.textInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        return attributedLabel
    }()

    public let reactionsView = ReactionsView()
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
        isAccessibilityElement = false
        self.accessibilityElementsHidden = false

        backgroundColor = .clear
        clipsToBounds = true
    }
    
    private func setupViews() {
        reactionsView.accessibilityIdentifier = "reactionsView"

        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.accessibilityIdentifier = "likeButton"
        likeButton.accessibilityLabel = "likeButton"
        likeButton.addTarget(self, action: #selector(requestLike), for: .touchUpInside)
        likeButton.setIcon(.liked, with: .like, for: .normal)
        likeButton.setIconColor(UIColor.from(scheme: .textDimmed), for: .normal)
        likeButton.setIcon(.liked, with: .like, for: .selected)
        likeButton.setIconColor(UIColor(for: .vividRed), for: .selected)
        likeButton.hitAreaPadding = CGSize(width: 20, height: 20)

        statusLabel.delegate = self
        statusLabel.extendsLinkTouchArea = true
        statusLabel.isUserInteractionEnabled = true
        statusLabel.verticalAlignment = .center
        statusLabel.isAccessibilityElement = true
        statusLabel.accessibilityLabel = "DeliveryStatus"
        statusLabel.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        statusLabel.numberOfLines = 0
        statusLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        statusLabel.linkAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber,
                                      NSAttributedString.Key.foregroundColor: UIColor.vividRed]
        statusLabel.activeLinkAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber,
                                            NSAttributedString.Key.foregroundColor: UIColor.vividRed.withAlphaComponent(0.5)]

        [likeButtonContainer, likeButton, statusLabel, reactionsView].forEach(addSubview)
    }
    
    private func createConstraints() {
        likeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = self.heightAnchor.constraint(equalToConstant: 28)
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

            // statusLabel
            statusLabel.leadingAnchor.constraint(equalTo: likeButtonContainer.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: topAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: reactionsView.leadingAnchor, constant: -UIView.conversationLayoutMargins.right),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            // reactionsView
            reactionsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIView.conversationLayoutMargins.right),
            reactionsView.centerYAnchor.constraint(equalTo: centerYAnchor)
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

        self.configureLikedState(message)
        self.layoutIfNeeded()

        if !self.forceShowTimestamp && message.hasReactions() {
            showReactionsView(true, animated: animated)
            self.configureReactions(message, animated: animated)
            self.tapGestureRecogniser.isEnabled = true
        }
        else {
            showReactionsView(false, animated: animated)
            self.configureTimestamp(message, animated: animated)
            self.tapGestureRecogniser.isEnabled = false
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
            configureLikedState(change.message)
        }
    }
    
    override open func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            stopCountdownTimer()
        }
    }
    
    fileprivate func showReactionsView(_ show: Bool, animated: Bool) {
        guard show == reactionsView.isHidden else { return }

        if show {
            reactionsView.alpha = 0
            reactionsView.isHidden = false
        }

        let animations = {
            self.reactionsView.alpha = show ? 1 : 0
        }

        UIView.animate(withDuration: animated ? 0.2 : 0, animations: animations, completion: { _ in
            self.reactionsView.isHidden = !show
        }) 
    }
    
    fileprivate func configureLikedState(_ message: ZMConversationMessage) {
        likeButton.isHidden = !message.canBeLiked
        likeButton.setSelected(message.liked, animated: false)
        self.reactionsView.likers = message.likers()
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
        
        let attributes: [NSAttributedString.Key : AnyObject] = [.font: statusLabel.font, .foregroundColor: statusLabel.textColor]
        let likersNamesAttributedString = likersNames && attributes

        let framesetter = CTFramesetterCreateWithAttributedString(likersNamesAttributedString)
        let targetSize = CGSize(width: 10000, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, likersNamesAttributedString.length), nil, targetSize, nil)

        let attributedText: NSAttributedString
        if labelSize.width > (statusLabel.bounds.width - reactionsView.bounds.width) {
            let likersCount = String(format: "participants.people.count".localized, likers.count)
            attributedText = likersCount && attributes
        }
        else {
            attributedText = likersNamesAttributedString
        }

        if let currentText = self.statusLabel.attributedText, currentText.string == attributedText.string {
            return
        }
        
        let changeBlock = {
            self.updateStatusLabelAttributedText(attributedText: attributedText)
        }
        
        if animated {
            statusLabel.wr_animateSlideTo(.down, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }

    fileprivate func updateStatusLabelAttributedText(attributedText: NSAttributedString) {
        statusLabel.attributedText = attributedText
        statusLabel.accessibilityValue = statusLabel.attributedText.string
    }

    fileprivate func configureTimestamp(_ message: ZMConversationMessage, animated: Bool = false) {
        var deliveryStateString: String? = .none
        
        if let sender = message.sender, sender.isSelfUser {
            switch message.deliveryState {
            case .pending:
                deliveryStateString = "content.system.pending_message_timestamp".localized
            case .delivered:
                deliveryStateString = "content.system.message_delivered_timestamp".localized
            case .sent:
                deliveryStateString = "content.system.message_sent_timestamp".localized
            case .failedToSend:
                deliveryStateString = "content.system.failedtosend_message_timestamp".localized + " " +
                                      "content.system.failedtosend_message_timestamp_resend".localized + " · " +
                                      "content.system.failedtosend_message_timestamp_delete".localized
            default:
                deliveryStateString = .none
            }
        }

        let showDestructionTimer = message.isEphemeral && !message.isObfuscated && nil != message.destructionDate
        if let destructionDate = message.destructionDate, showDestructionTimer {
            let remaining = destructionDate.timeIntervalSinceNow + 1 // We need to add one second to start with the correct value
            
            if remaining > 0 {
                deliveryStateString = MessageToolboxView.ephemeralTimeFormatter.string(from: remaining)
            } else if message.isAudio {
                // do nothing, audio messages are allowed to extend the timer
                // past the destruction date.
            }
        }

        let finalText: String

        if let childMessages = message.systemMessageData?.childMessages,
            !childMessages.isEmpty,
            let timestamp = timestampString(message) {
            let childrenTimestamps = childMessages.compactMap {
                $0 as? ZMConversationMessage
            }.sorted { left, right in
                left.serverTimestamp < right.serverTimestamp
            }.compactMap(timestampString)

            finalText = childrenTimestamps.reduce(timestamp) { (text, current) in
                return "\(text)\n\(current)"
            }
        } else if let timestampString = self.timestampString(message), message.deliveryState == .delivered || message.deliveryState == .sent {
            if let deliveryStateString = deliveryStateString, Message.shouldShowDeliveryState(message) {
                finalText = timestampString + " ・ " + deliveryStateString
            }
            else {
                finalText = timestampString
            }
        }
        else {
            finalText = (deliveryStateString ?? "")
        }
        
        if statusLabel.attributedText?.string == finalText {
            return
        }
        
        let attributedText = NSMutableAttributedString(attributedString: finalText && [.font: statusLabel.font, .foregroundColor: statusLabel.textColor])
        
        if message.deliveryState == .failedToSend {
            let linkRange = (finalText as NSString).range(of: "content.system.failedtosend_message_timestamp_resend".localized)
            attributedText.addAttributes([.link: type(of: self).resendLink], range: linkRange)
            
            let deleteRange = (finalText as NSString).range(of: "content.system.failedtosend_message_timestamp_delete".localized)
            attributedText.addAttributes([.link: type(of: self).deleteLink], range: deleteRange)
        }

        if let currentText = self.statusLabel.attributedText, currentText.string == attributedText.string {
            return
        }
        
        let changeBlock =  {
            self.updateStatusLabelAttributedText(attributedText: attributedText)
            self.statusLabel.addLinks()
        }
        
        if animated {
            statusLabel.wr_animateSlideTo(.up, newState: changeBlock)
        }
        else {
            changeBlock()
        }
    }
    
    fileprivate func configureLikeTip(_ message: ZMConversationMessage, animated: Bool = false) {
        let likeTooltipText = "content.system.like_tooltip".localized
        let attributes: [NSAttributedString.Key : AnyObject] = [.font: statusLabel.font, .foregroundColor: statusLabel.textColor]
        let attributedText = likeTooltipText && attributes

        if let currentText = self.statusLabel.attributedText, currentText.string == attributedText.string {
            return
        }
        
        let changeBlock = {
            self.updateStatusLabelAttributedText(attributedText: attributedText)
        }
        
        if animated {
            statusLabel.wr_animateSlideTo(.up, newState: changeBlock)
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
        guard !forceShowTimestamp else { return }
        if let message = self.message , !message.likers().isEmpty {
            self.delegate?.messageToolboxViewDidSelectLikers(self)
        }
    }
    
    @objc func prepareForReuse() {
        self.message = nil
    }
}


extension MessageToolboxView: TTTAttributedLabelDelegate {
    
    // MARK: - TTTAttributedLabelDelegate
    
    public func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith URL: Foundation.URL!) {
        if URL == type(of: self).resendLink {
            self.delegate?.messageToolboxViewDidSelectResend(self)
        }
        else if URL == type(of: self).deleteLink {
            self.delegate?.messageToolboxViewDidSelectDelete(self)
        }
    }
}

extension MessageToolboxView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isEqual(self.tapGestureRecogniser)
    }
}
