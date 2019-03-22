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

class ConversationLinkAttachmentCell: UIView, ConversationMessageCell {

    struct Configuration {
        let attachment: LinkAttachment
        let thumbnailResource: ImageResource?
    }

    let attachmentView = MediaPreviewView()

    weak var delegate: ConversationMessageCellDelegate? = nil
    weak var message: ZMConversationMessage? = nil

    var isSelected: Bool = false
    var currentAttachment: LinkAttachment?
    var widthConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        addSubview(attachmentView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        attachmentView.addGestureRecognizer(tapGesture)
    }

    private func configureConstraints() {
        attachmentView.translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = attachmentView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            attachmentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            attachmentView.topAnchor.constraint(equalTo: topAnchor),
            attachmentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            attachmentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            attachmentView.heightAnchor.constraint(equalToConstant: 160),
            widthConstraint
        ])
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        currentAttachment = object.attachment
        attachmentView.titleLabel.text = object.attachment.title
        attachmentView.previewImageView.setImageResource(object.thumbnailResource, hideLoadingView: true)

        switch object.attachment.type {
        case .youTubeVideo:
            widthConstraint?.constant = 60

        case .soundCloudPlaylist, .soundCloudTrack:
            widthConstraint?.constant = 60
        }
    }

    // MARK: - Events

    @objc private func handleTapGesture() {
        currentAttachment?.permalink.open()
    }

}

class ConversationLinkAttachmentCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLinkAttachmentCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 8

    let isFullWidth: Bool = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(attachment: LinkAttachment, thumbnailResource: ImageResource?) {
        configuration = View.Configuration(attachment: attachment, thumbnailResource: thumbnailResource)
        actionController = nil
    }
}
