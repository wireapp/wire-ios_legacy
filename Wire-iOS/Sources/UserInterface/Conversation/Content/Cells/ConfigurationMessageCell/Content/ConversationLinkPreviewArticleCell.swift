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

class ConversationLinkPreviewArticleCell: UIView, ConversationMessageCell {

    struct Configuration {
        let textMessageData: ZMTextMessageData
        let isObfuscated: Bool
    }

    var isSelected: Bool = false
    private let articleView = ArticleView(withImagePlaceholder: true)

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
        addSubview(articleView)
    }

    private func configureConstraints() {
        articleView.translatesAutoresizingMaskIntoConstraints = false
        articleView.fitInSuperview()
    }

    func configure(with object: Configuration) {
        articleView.configure(withTextMessageData: object.textMessageData, obfuscated: object.isObfuscated)
    }

}

class ConversationLinkPreviewArticleCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLinkPreviewArticleCell
    let configuration: View.Configuration

    weak var delegate: ConversationCellDelegate?

    var isFullWidth: Bool {
        return false
    }

    init(message: ZMConversationMessage, data: ZMTextMessageData) {
        configuration = View.Configuration(textMessageData: data, isObfuscated: message.isObfuscated)
    }
}
