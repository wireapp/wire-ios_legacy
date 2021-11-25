//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireShareEngine

final class TargetConversationCell: UITableViewCell {

    let conversationNameLabel = UILabel()
    let stateAccessoryView = ConversationStateAccessoryView()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        contentView.addSubview(stateAccessoryView)

        conversationNameLabel.textColor = UIColor.Wire.primaryLabel
        conversationNameLabel.font = .preferredFont(forTextStyle: .body)
        contentView.addSubview(conversationNameLabel)
    }

    private func configureConstraints() {
        conversationNameLabel.translatesAutoresizingMaskIntoConstraints = false
        stateAccessoryView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stateAccessoryView
            stateAccessoryView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stateAccessoryView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // conversationNameLabel
            conversationNameLabel.leadingAnchor.constraint(equalTo: stateAccessoryView.trailingAnchor, constant: 8),
            conversationNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            conversationNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
            conversationNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            conversationNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }

    // MARK: - Configuration

    override func prepareForReuse() {
        super.prepareForReuse()
        accessibilityLabel = nil
        conversationNameLabel.text = nil
        stateAccessoryView.prepareForReuse()
    }

    func configure(for conversation: Conversation) {
        // Subviews
        conversationNameLabel.text = conversation.name
        stateAccessoryView.configure(for: conversation)

        // Accessibility
        updateAccessibility(for: conversation)
    }

    private func updateAccessibility(for conversation: Conversation) {
        var details: [String] = []

        if conversation.legalHoldStatus.denotesEnabledComplianceDevice {
            details.append("share_extension.voiceover.conversation_under_legal_hold".localized)
        }

        switch conversation.securityLevel {
        case .notSecure:
            break
        case .secureWithIgnored:
            details.append("share_extension.voiceover.conversation_secure_with_ignored".localized)
        case .secure:
            details.append("share_extension.voiceover.conversation_secure".localized)
        }

        accessibilityLabel = conversation.name
        accessibilityValue = details.joined(separator: ", ")
    }

}
