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

class ConversationMessageToolboxCell: UIView, ConversationMessageCell, MessageToolboxViewDelegate {

    struct Configuration {
        let message: ZMConversationMessage
    }

    let toolboxView = MessageToolboxView()
    weak var delegate: ConversationCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false
    var observerToken: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        toolboxView.delegate = self
        addSubview(toolboxView)
    }

    private func configureConstraints() {
        toolboxView.translatesAutoresizingMaskIntoConstraints = false
        toolboxView.fitInSuperview()
    }

    func configure(with object: Configuration) {
        toolboxView.configureForMessage(object.message, forceShowTimestamp: false, animated: false)
    }

    func messageToolboxViewDidRequestLike(_ messageToolboxView: MessageToolboxView) {
        delegate?.conversationCell?(self, didSelect: .like, for: message)
    }

    func messageToolboxViewDidSelectDelete(_ messageToolboxView: MessageToolboxView) {
        delegate?.conversationCell?(self, didSelect: .delete, for: message)
    }

    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView) {
        delegate?.conversationCell?(self, didSelect: .resend, for: message)
    }

    func messageToolboxViewDidSelectLikers(_ messageToolboxView: MessageToolboxView) {
        delegate?.conversationCellDidTapOpenLikers?(self, for: message)
    }

}

class ConversationMessageToolboxCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationMessageToolboxCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate? 
    weak var actionController: ConversationCellActionController?

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
        
    init(message: ZMConversationMessage) {
        self.message = message
        self.configuration = View.Configuration(message: message)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueConversationCell(with: self, for: indexPath)
        cell.cellView.delegate = self.delegate
        cell.cellView.message = self.message
        return cell
    }

}
