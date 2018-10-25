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

class ConversationLinkAttachmentCell: UIView, ConversationMessageCell {

    struct Configuration {
        let contentViewController: UIViewController
    }

    var isSelected: Bool = false
    private var contentViewController: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func configure(with object: Configuration) {
        let contentViewController = object.contentViewController
        addSubview(contentViewController.view)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.view.fitInSuperview()

        self.contentViewController = contentViewController
    }

}

class ConversationLinkAttachmentCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLinkAttachmentCell
    let configuration: View.Configuration

    let isFullWidth: Bool

    init(contentViewController: UIViewController, linkAttachmentType: LinkAttachmentType) {
        self.configuration = View.Configuration(contentViewController: contentViewController)
        isFullWidth = linkAttachmentType != .youtubeVideo
    }
}
