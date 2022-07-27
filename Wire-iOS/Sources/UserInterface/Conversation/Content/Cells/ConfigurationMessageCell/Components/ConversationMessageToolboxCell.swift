//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireDataModel

final class ConversationMessageToolboxCell: UIView, ConversationMessageCell, MessageToolboxViewDelegate {

    struct Configuration: Equatable {
        let message: ZMConversationMessage
        let selected: Bool
        let deliveryState: ZMDeliveryState

        static func == (lhs: ConversationMessageToolboxCell.Configuration, rhs: ConversationMessageToolboxCell.Configuration) -> Bool {
            return lhs.deliveryState == rhs.deliveryState &&
                   lhs.message == rhs.message &&
                   lhs.selected == rhs.selected
        }
    }

    let toolboxView = MessageToolboxView()
    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false
    var observerToken: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        toolboxView.delegate = self
        addSubview(toolboxView)
    }

    private func configureConstraints() {
        toolboxView.translatesAutoresizingMaskIntoConstraints = false
        toolboxView.fitIn(view: self)
    }

    func willDisplay() {
        toolboxView.startCountdownTimer()
    }

    func didEndDisplaying() {
        toolboxView.stopCountdownTimer()
    }

    func configure(with object: Configuration, animated: Bool) {
        toolboxView.configureForMessage(object.message, forceShowTimestamp: object.selected, animated: animated)
    }

    func messageToolboxDidRequestOpeningDetails(_ messageToolboxView: MessageToolboxView, preferredDisplayMode: MessageDetailsDisplayMode) {
        let detailsViewController = MessageDetailsViewController(message: message!, preferredDisplayMode: preferredDisplayMode)
        delegate?.conversationMessageWantsToOpenMessageDetails(self, messageDetailsViewController: detailsViewController)
    }

    private func perform(action: MessageAction, sender: UIView? = nil) {
        delegate?.perform(action: action, for: message, view: selectionView ?? sender ?? self)
    }

    func messageToolboxViewDidRequestLike(_ messageToolboxView: MessageToolboxView) {
        perform(action: .like)
    }

    func messageToolboxViewDidSelectDelete(_ sender: UIView?) {
        perform(action: .delete, sender: sender)
    }

    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView) {
        perform(action: .resend)
    }

}

final class ConversationMessageToolboxCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationMessageToolboxCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 2
    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = "MessageToolbox"
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, selected: Bool) {
        self.message = message
        self.configuration = View.Configuration(message: message, selected: selected, deliveryState: message.deliveryState)
    }

}
