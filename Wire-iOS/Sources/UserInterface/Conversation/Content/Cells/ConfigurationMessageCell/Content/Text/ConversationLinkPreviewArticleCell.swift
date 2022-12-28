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

final class ConversationLinkPreviewArticleCell: UIView, ConversationMessageCell, ContextMenuDelegate {

    struct Configuration {
        let textMessageData: ZMTextMessageData
        let showImage: Bool
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            return message.isObfuscated
        }
    }

    private let articleView = ArticleView(withImagePlaceholder: true)

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    var selectionView: UIView? {
        return articleView
    }

    var configuration: Configuration?

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
        articleView.delegate = self
        addSubview(articleView)
    }

    private func configureConstraints() {
        articleView.translatesAutoresizingMaskIntoConstraints = false
        articleView.fitIn(view: self)
    }

    func configure(with object: Configuration, animated: Bool) {
        configuration = object
        articleView.configure(withTextMessageData: object.textMessageData,
                              obfuscated: object.isObfuscated)

        updateImageLayout(isRegular: traitCollection.horizontalSizeClass == .regular)
    }

    func updateImageLayout(isRegular: Bool) {
        if configuration?.showImage == true {
            articleView.imageHeight = isRegular ? 250 : 150
        } else {
            articleView.imageHeight = 0
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateImageLayout(isRegular: self.traitCollection.horizontalSizeClass == .regular)
    }

}

extension ConversationLinkPreviewArticleCell: LinkViewDelegate {
    var url: URL? {
        return configuration?.textMessageData.linkPreview?.openableURL
    }
}

final class ConversationLinkPreviewArticleCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLinkPreviewArticleCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 8

    let isFullWidth: Bool = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    var accessibilityIdentifier: String? {
        return configuration.isObfuscated ? "ObfuscatedLinkPreviewCell" : "LinkPreviewCell"
    }

    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMTextMessageData) {
        let showImage = data.linkPreviewHasImage
        configuration = View.Configuration(textMessageData: data, showImage: showImage, message: message)
        accessibilityLabel = L10n.Accessibility.ConversationSearch.LinkMessage.description
    }
}
