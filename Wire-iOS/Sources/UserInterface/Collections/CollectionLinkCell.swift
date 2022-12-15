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
import UIKit
import WireDataModel
import WireCommonComponents

final class CollectionLinkCell: CollectionCell {
    private var articleView: ArticleView? = .none
    private var headerView = CollectionCellHeader()

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
    }

    func createArticleView(with textMessageData: ZMTextMessageData) {
        let articleView = ArticleView(withImagePlaceholder: textMessageData.linkPreviewHasImage)
        articleView.isUserInteractionEnabled = false
        articleView.imageHeight = 0
        articleView.messageLabel.numberOfLines = 1
        articleView.authorLabel.numberOfLines = 1
        articleView.configure(withTextMessageData: textMessageData,
                              obfuscated: false)
        secureContentsView.addSubview(articleView)
        // Reconstraint the header
        headerView.removeFromSuperview()
        headerView.message = message!

        secureContentsView.addSubview(headerView)

        contentView.layoutMargins = UIEdgeInsets(top: 16, left: 4, bottom: 4, right: 4)

        [articleView, headerView].prepareForLayout()
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: -12),

          articleView.topAnchor.constraint(greaterThanOrEqualTo: headerView.bottomAnchor, constant: -4),
            articleView.leftAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leftAnchor),
            articleView.rightAnchor.constraint(equalTo: contentView.layoutMarginsGuide.rightAnchor),
            articleView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])

        self.articleView = articleView
    }

    override var obfuscationIcon: StyleKitIcon {
        return .link
    }

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        typealias ConversationSearch = L10n.Accessibility.ConversationSearch

        super.updateForMessage(changeInfo: changeInfo)

        guard let message = message, let textMessageData = message.textMessageData, textMessageData.linkPreview != nil else {
            return
        }

        var shouldReload = false

        if changeInfo == nil {
            shouldReload = true
        } else {
            shouldReload = changeInfo!.imageChanged
        }

        if shouldReload {
            articleView?.removeFromSuperview()
            articleView = nil

            createArticleView(with: textMessageData)
        }
        accessibilityLabel = ConversationSearch.SentBy.description(message.senderName)
                            + ", \(message.serverTimestamp?.formattedDate ?? ""), "
                            + ConversationSearch.LinkMessage.description
        accessibilityHint = ConversationSearch.Item.hint
    }

    override func copyDisplayedContent(in pasteboard: UIPasteboard) {
        guard let link = message?.textMessageData?.linkPreview else { return }
        UIPasteboard.general.url = link.openableURL as URL?
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        message = .none
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
