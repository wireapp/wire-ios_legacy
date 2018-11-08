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

struct BurstTimestampSenderMessageCellConfiguration {
    let date: Date
    let includeDayOfWeek: Bool
    let showUnreadDot: Bool
}

class BurstTimestampSenderMessageCellDescription: ConversationMessageCellDescription {
    
    typealias View = BurstTimestampSenderMessageCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationCellActionController?

    var isFullWidth: Bool {
        return true
    }

    var supportsActions: Bool {
        return false
    }

    init(message: ZMConversationMessage, context: ConversationMessageContext) {
        self.configuration = View.Configuration(date: message.serverTimestamp ?? Date(), includeDayOfWeek: context.isFirstMessageOfTheDay, showUnreadDot: context.isFirstUnreadMessage)
        actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }
    
}

class BurstTimestampSenderMessageCell: UIView, ConversationMessageCell {

    private let timestampView = ConversationCellBurstTimestampView()

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
        addSubview(timestampView)
    }

    private func configureConstraints() {
        timestampView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            timestampView.leadingAnchor.constraint(equalTo: leadingAnchor),
            timestampView.topAnchor.constraint(equalTo: topAnchor),
            timestampView.trailingAnchor.constraint(equalTo: trailingAnchor),
            timestampView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Cell

    var isSelected: Bool = false

    func configure(with object: BurstTimestampSenderMessageCellConfiguration, animated: Bool) {
        timestampView.configure(with: object.date, includeDayOfWeek: object.includeDayOfWeek, showUnreadDot: object.showUnreadDot)
    }

}
