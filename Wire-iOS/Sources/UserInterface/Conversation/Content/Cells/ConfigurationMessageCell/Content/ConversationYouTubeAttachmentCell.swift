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

class ConversationYouTubeAttachmentCell: UIView, ConversationMessageCell {

    struct Configuration {
        let attachment: LinkAttachment
    }

    var isSelected: Bool = false
    private let mediaPreviewController = MediaPreviewViewController()

    // MARK: - Initialization

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
        addSubview(mediaPreviewController.view)
    }

    private func configureConstraints() {
        mediaPreviewController.view.translatesAutoresizingMaskIntoConstraints = false
        mediaPreviewController.view.fitInSuperview()
    }

    func configure(with object: Configuration) {
        mediaPreviewController.linkAttachment = object.attachment
        mediaPreviewController.fetchAttachment()
    }

}

class ConversationYouTubeAttachmentCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationYouTubeAttachmentCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return false
    }

    init(attachment: LinkAttachment) {
        configuration = View.Configuration(attachment: attachment)
    }
}
