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
import WireDataModel

/// Observes events from the message toolbox.
protocol MessageToolboxViewDelegate: class {
    func messageToolboxDidRequestOpeningDetails(_ messageToolboxView: MessageToolboxView, preferredDisplayMode: MessageDetailsDisplayMode)
    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectDelete(_ sender: UIView?)
    func messageToolboxViewDidRequestLike(_ messageToolboxView: MessageToolboxView)
}

private extension UILabel {
    static func createSeparatorLabel() -> UILabel{
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.from(scheme: .textDimmed)
        label.font = UIFont.smallSemiboldFont
        label.text = String.MessageToolbox.middleDot
        label.isAccessibilityElement = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }
}

/**
 * A view that displays information about a message.
 */

final class MessageToolboxView: UIView {

    /// The object receiving events.
    weak var delegate: MessageToolboxViewDelegate?

    ///
    fileprivate(set) var dataSource: MessageToolboxDataSource?

    // MARK: - UI Elements

    /// The timer for ephemeral messages.
    private var timestampTimer: Timer? = nil

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 3
        stack.isAccessibilityElement = false
        return stack
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "Details"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let timestampSeparatorLabel = UILabel.createSeparatorLabel()
    private let statusSeparatorLabel = UILabel.createSeparatorLabel()

    private let resendButton: UIButton = {
        let button = UIButton()
        let attributedTitle = NSAttributedString(string: "content.system.failedtosend_message_timestamp_resend".localized,
                                                 attributes: [.foregroundColor: UIColor.vividRed,
                                                              .underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber,
                                                              .font: UIFont.smallSemiboldFont])

        button.contentHorizontalAlignment = .left
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        let attributedTitle = NSAttributedString(string: "content.system.failedtosend_message_timestamp_delete".localized,
                                                 attributes: [.foregroundColor: UIColor.vividRed,
                                                              .underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber,
                                                              .font: UIFont.smallSemiboldFont])

        button.contentHorizontalAlignment = .left
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "DeliveryStatus"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "EphemeralCountdown"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    fileprivate var tapGestureRecogniser: UITapGestureRecognizer!

    fileprivate let likeButton = LikeButton()
    fileprivate let likeButtonContainer = UIView()
    fileprivate var likeButtonWidth: NSLayoutConstraint!
    fileprivate var heightConstraint: NSLayoutConstraint!
    fileprivate var previousLayoutBounds: CGRect = CGRect.zero
    fileprivate var forceShowTimestamp: Bool = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
                
        setupViews()
        createConstraints()
        
        tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(MessageToolboxView.onTapContent(_:)))
        tapGestureRecogniser.delegate = self
        addGestureRecognizer(tapGestureRecogniser)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        likeButton.accessibilityIdentifier = "likeButton"
        likeButton.addTarget(self, action: #selector(requestLike), for: .touchUpInside)
        likeButton.setIconColor(LikeButton.normalColor, for: .normal)
        likeButton.setIconColor(LikeButton.selectedColor, for: .selected)
        likeButton.hitAreaPadding = CGSize(width: 20, height: 20)

        resendButton.addTarget(self, action: #selector(resendMessage), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteMessage), for: .touchUpInside)

        [detailsLabel,
         resendButton,
         timestampSeparatorLabel,
         deleteButton,
         statusLabel,
         statusSeparatorLabel,
         countdownLabel].forEach(contentStack.addArrangedSubview)
        [likeButtonContainer, likeButton, contentStack].forEach(addSubview)
    }
    
    private func createConstraints() {
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 28)
        heightConstraint.priority = UILayoutPriority(999)

        likeButtonWidth = likeButtonContainer.widthAnchor.constraint(equalToConstant: conversationHorizontalMargins.left)

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
            contentStack.leadingAnchor.constraint(equalTo: likeButtonContainer.trailingAnchor),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -conversationHorizontalMargins.right),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let message = self.dataSource?.message else { return }
        guard !self.bounds.equalTo(self.previousLayoutBounds) else {
            return
        }

        self.previousLayoutBounds = self.bounds
        self.configureForMessage(message, forceShowTimestamp: self.forceShowTimestamp)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            stopCountdownTimer()
        }
    }

    func prepareForReuse() {
        dataSource = nil
        stopCountdownTimer()
    }

    // MARK: - Configuration

    private var contentWidth: CGFloat {
        return bounds.width - conversationHorizontalMargins.left - conversationHorizontalMargins.right
    }

    func configureForMessage(_ message: ZMConversationMessage, forceShowTimestamp: Bool, animated: Bool = false) {
        if dataSource?.message.nonce != message.nonce {
            dataSource = MessageToolboxDataSource(message: message)
        }
        
        self.forceShowTimestamp = forceShowTimestamp
        reloadContent(animated: animated)
    }

    private func hideAndCleanStatusLabel() {
        statusLabel.isHidden = true
        statusLabel.accessibilityLabel = nil
        statusLabel.attributedText = nil
    }

    private func reloadContent(animated: Bool) {
        guard let dataSource = self.dataSource else { return }

        // Do not reload the content if it didn't change.
        guard let newPosition = dataSource.updateContent(forceShowTimestamp: forceShowTimestamp, widthConstraint: contentWidth) else {
            return
        }

        switch dataSource.content {
            
        case .callList(let callListString):
            updateContentStack(to: newPosition, animated: animated) {
                self.detailsLabel.attributedText = callListString
                self.detailsLabel.isHidden = false
                self.detailsLabel.numberOfLines = 0
                self.hideAndCleanStatusLabel()
                self.timestampSeparatorLabel.isHidden = true
                self.deleteButton.isHidden = true
                self.resendButton.isHidden = true
                self.statusSeparatorLabel.isHidden = true
                self.countdownLabel.isHidden = true
            }
        case .reactions(let reactionsString, _):
            updateContentStack(to: newPosition, animated: animated) {
                self.detailsLabel.attributedText = reactionsString
                self.detailsLabel.isHidden = false
                self.detailsLabel.numberOfLines = 1
                self.hideAndCleanStatusLabel()
                self.timestampSeparatorLabel.isHidden = true
                self.deleteButton.isHidden = true
                self.resendButton.isHidden = true
                self.statusSeparatorLabel.isHidden = true
                self.countdownLabel.isHidden = true
            }

        case .sendFailure(let detailsString):
            updateContentStack(to: newPosition, animated: animated) {
                self.detailsLabel.attributedText = detailsString
                self.detailsLabel.isHidden = false
                self.detailsLabel.numberOfLines = 1
                self.hideAndCleanStatusLabel()
                self.timestampSeparatorLabel.isHidden = false
                self.deleteButton.isHidden = false
                self.resendButton.isHidden = false
                self.statusSeparatorLabel.isHidden = true
                self.countdownLabel.isHidden = true
            }

        case .details(let timestamp, let status, let countdown, _):
            updateContentStack(to: newPosition, animated: animated) {
                self.detailsLabel.attributedText = timestamp
                self.detailsLabel.isHidden = timestamp == nil
                self.detailsLabel.numberOfLines = 1
                self.statusLabel.attributedText = status
                //override accessibilityLabel if the attributed string has customized accessibilityLabel
                if let accessibilityLabel = status?.accessibilityLabel {
                    self.statusLabel.accessibilityLabel = accessibilityLabel
                }
                self.statusLabel.isHidden = status == nil
                self.timestampSeparatorLabel.isHidden = timestamp == nil || status == nil
                self.deleteButton.isHidden = true
                self.resendButton.isHidden = true
                self.statusSeparatorLabel.isHidden = (timestamp == nil && status == nil) || countdown == nil
                self.countdownLabel.attributedText = countdown
                self.countdownLabel.isHidden = countdown == nil
            }
        }

        configureLikedState(dataSource.message, animated: animated)
        layoutIfNeeded()
    }

    // MARK: - Timer

    /// Starts the countdown timer.
    func startCountdownTimer() {
        stopCountdownTimer()

        guard let message = self.dataSource?.message else { return }
        guard message.isEphemeral, !message.hasBeenDeleted, !message.isObfuscated else { return }
        
        timestampTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.reloadContent(animated: false)
        }
    }

    /// Stops the countdown timer.
    func stopCountdownTimer() {
        timestampTimer?.invalidate()
        timestampTimer = nil
    }

    fileprivate func updateContentStack(to direction: SlideDirection, animated: Bool = false, changes: @escaping () -> Void) {
        if animated {
            contentStack.wr_animateSlideTo(direction, newState: changes)
        } else {
            changes()
        }
    }

    // MARK: - Hiding the Contents

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

    // MARK: - Actions

    @objc
    private func requestLike() {
        delegate?.messageToolboxViewDidRequestLike(self)
    }

    @objc
    private func resendMessage() {
        delegate?.messageToolboxViewDidSelectResend(self)
    }

    @objc
    private func deleteMessage(sender: UIView?) {
        delegate?.messageToolboxViewDidSelectDelete(sender)
    }

    func update(for change: MessageChangeInfo) {
        if change.reactionsChanged {
            configureLikedState(change.message, animated: true)
        }
    }

    /// Configures the like button.
    fileprivate func configureLikedState(_ message: ZMConversationMessage, animated: Bool) {
        let showLikeButton: Bool

        if case .reactions? = dataSource?.content {
            showLikeButton = message.liked || message.hasReactions()
        } else {
            showLikeButton = message.canBeLiked
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
        likeButton.accessibilityLabel = message.liked ? "content.message.unlike".localized : "content.message.like".localized
        likeButton.setIcon(message.liked ? .liked : .like, size: 12, for: .normal)
        likeButton.setIcon(.liked, size: 12, for: .selected)
        likeButton.setSelected(message.liked, animated: animated)

        // Animate Changes
        if needsAnimation {
            UIView.animate(withDuration: 0.2, animations: changes, completion: completion)
        } else {
            changes()
            completion(true)
        }
    }

}

// MARK: - Tap Gesture

extension MessageToolboxView: UIGestureRecognizerDelegate {

    @objc
    func onTapContent(_ sender: UITapGestureRecognizer!) {
        if let displayMode = preferredDetailsDisplayMode() {
            delegate?.messageToolboxDidRequestOpeningDetails(self, preferredDisplayMode: displayMode)
        }
    }

    func preferredDetailsDisplayMode() -> MessageDetailsDisplayMode? {
        guard let dataSource = self.dataSource else { return nil }

        switch dataSource.content {
        case .sendFailure:
            break
        case .reactions where dataSource.message.areMessageDetailsAvailable:
            return .reactions
        case .details where dataSource.message.areReadReceiptsDetailsAvailable:
            return .receipts
        default:
            break
        }

        return nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isEqual(self.tapGestureRecogniser)
    }

}
