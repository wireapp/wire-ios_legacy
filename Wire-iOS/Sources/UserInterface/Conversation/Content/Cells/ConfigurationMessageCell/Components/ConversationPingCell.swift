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

import Foundation

class ConversationPingCell: UIView, ConversationMessageCell {

    struct Configuration {
        let pingColor: UIColor
        let pingText: NSAttributedString
    }

    private let imageContainer = UIView()
    private let pingImageView = UIImageView()
    private let pingLabel = UILabel()

    private var containerWidthConstraint: NSLayoutConstraint!
    private var labelTrailingConstraint: NSLayoutConstraint!

    var isSelected: Bool = false

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
        pingImageView.contentMode = .center
        imageContainer.addSubview(pingImageView)
        addSubview(imageContainer)
        addSubview(pingLabel)
    }

    private func configureConstraints() {
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        pingImageView.translatesAutoresizingMaskIntoConstraints = false
        pingLabel.translatesAutoresizingMaskIntoConstraints = false

        containerWidthConstraint = imageContainer.widthAnchor.constraint(equalToConstant: UIView.conversationLayoutMargins.left)
        labelTrailingConstraint = pingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIView.conversationLayoutMargins.right)

        NSLayoutConstraint.activate([
            // imageContainer
            containerWidthConstraint,
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.topAnchor.constraint(equalTo: topAnchor),
            imageContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageContainer.heightAnchor.constraint(equalTo: pingImageView.heightAnchor),

            // pingImageView
            pingImageView.widthAnchor.constraint(equalToConstant: 32),
            pingImageView.heightAnchor.constraint(equalToConstant: 32),
            pingImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            pingImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            // pingLabel
            pingLabel.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            pingLabel.topAnchor.constraint(equalTo: topAnchor),
            pingLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            labelTrailingConstraint
        ])
    }

    func configure(with object: Configuration) {
        pingLabel.attributedText = object.pingText
        pingImageView.image = UIImage(for: .ping, fontSize: 20, color: object.pingColor)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        containerWidthConstraint.constant = UIView.conversationLayoutMargins.left
        labelTrailingConstraint.constant = -UIView.conversationLayoutMargins.right
    }

}

class ConversationPingCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationPingCell
    let configuration: ConversationPingCell.Configuration

    var isFullWidth: Bool {
        return true
    }

    init(message: ZMConversationMessage, sender: ZMUser) {
        let senderText = sender.isSelfUser ? "content.ping.text.you".localized : sender.displayName
        let pingText = "content.ping.text".localized(pov: sender.pov, args: senderText)

        let text = NSAttributedString(string: pingText, attributes: [.font: UIFont.mediumFont])
        let pingColor: UIColor = message.isObfuscated ? .accentDimmedFlat : sender.accentColor
        self.configuration = View.Configuration(pingColor: pingColor, pingText: text)
    }

}
