//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import UIKit
import WireSyncEngine

final class TextSearchResultCell: UITableViewCell {
    fileprivate let messageTextLabel = SearchResultLabel()
    fileprivate let footerView = TextSearchResultFooter()
    fileprivate let userImageViewContainer = UIView()
    fileprivate let userImageView = UserImageView()
    fileprivate let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        return view
    }()
    fileprivate var observerToken: Any?
    let resultCountView: RoundedTextBadge = {
        let roundedTextBadge = RoundedTextBadge()
        roundedTextBadge.backgroundColor = SemanticColors.View.backgroundDefaultBlack

        return roundedTextBadge
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        userImageView.userSession = ZMUserSession.shared()
        userImageView.initialsFont = .systemFont(ofSize: 11, weight: .light)

        accessibilityIdentifier = "search result cell"

        contentView.addSubview(footerView)
        selectionStyle = .none
        messageTextLabel.accessibilityIdentifier = "text search result"
        messageTextLabel.numberOfLines = 1
        messageTextLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        messageTextLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)

        contentView.addSubview(messageTextLabel)

        userImageViewContainer.addSubview(userImageView)

        contentView.addSubview(userImageViewContainer)

        contentView.addSubview(separatorView)

        resultCountView.textLabel.accessibilityIdentifier = "count of matches"
        contentView.addSubview(resultCountView)

        createConstraints()

        textLabel?.textColor = SemanticColors.Label.textDefaultWhite
        textLabel?.font = .smallSemiboldFont
    }

    fileprivate func createConstraints() {
        [userImageView, userImageViewContainer, footerView, messageTextLabel, resultCountView, separatorView].prepareForLayout()
        NSLayoutConstraint.activate([
          userImageView.heightAnchor.constraint(equalToConstant: 24),
          userImageView.widthAnchor.constraint(equalTo: userImageView.heightAnchor),
          userImageView.centerXAnchor.constraint(equalTo: userImageViewContainer.centerXAnchor),
          userImageView.centerYAnchor.constraint(equalTo: userImageViewContainer.centerYAnchor),

          userImageViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
          userImageViewContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
          userImageViewContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          userImageViewContainer.widthAnchor.constraint(equalToConstant: 48),

          messageTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
          messageTextLabel.leadingAnchor.constraint(equalTo: userImageViewContainer.trailingAnchor),
          messageTextLabel.trailingAnchor.constraint(equalTo: resultCountView.leadingAnchor, constant: -16),
          messageTextLabel.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -4),

          footerView.leadingAnchor.constraint(equalTo: userImageViewContainer.trailingAnchor),
          footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
          footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

          resultCountView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
          resultCountView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
          resultCountView.heightAnchor.constraint(equalToConstant: 20),
          resultCountView.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),

          separatorView.leadingAnchor.constraint(equalTo: userImageViewContainer.trailingAnchor),
          separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
          separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          separatorView.heightAnchor.constraint(equalToConstant: .hairline)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        message = .none
        queries = []
    }

    private func updateTextView() {
        guard let message = message else {
            return
        }

        if message.isObfuscated {
            let obfuscatedText = messageTextLabel.text?.obfuscated() ?? ""
            messageTextLabel.configure(with: obfuscatedText, queries: [])
            messageTextLabel.isObfuscated = true
            return
        }

        guard let text = message.textMessageData?.messageText else {
            return
        }

        messageTextLabel.configure(with: text, queries: queries)

        let totalMatches = messageTextLabel.estimatedMatchesCount

        resultCountView.isHidden = totalMatches <= 1
        resultCountView.textLabel.text = "\(totalMatches)"
        resultCountView.updateCollapseConstraints(isCollapsed: false)
    }

    func configure(with newMessage: ZMConversationMessage, queries newQueries: [String]) {
        message = newMessage
        queries = newQueries

        userImageView.user = newMessage.senderUser
        footerView.message = newMessage
        if let userSession = ZMUserSession.shared() {
            observerToken = MessageChangeInfo.add(observer: self,
                                                  for: newMessage,
                                                  userSession: userSession)
        }

        updateTextView()
    }

    var message: ZMConversationMessage? = .none
    var queries: [String] = []

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        let backgroundColor = SemanticColors.View.backgroundDefault
        let backgroundIsHighlighted = SemanticColors.View.backgroundUserCellHightLighted

        contentView.backgroundColor = highlighted ? backgroundIsHighlighted : backgroundColor
    }
}

extension TextSearchResultCell: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        updateTextView()
    }
}
