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

protocol PlayerViewControllerProtocol: class, LinkAttachmentPresenter {
    var providerImage: UIImage! { get set }
    var sourceMessage: ZMConversationMessage! { get set }
}

extension AudioTrackViewController: PlayerViewControllerProtocol {}
extension AudioPlaylistViewController: PlayerViewControllerProtocol {}

class ConversationSoundCloudAttachmentCell<Player: UIViewController & PlayerViewControllerProtocol>: ViewControllerBasedCell<Player>, ConversationMessageCell {

    struct Configuration {
        let attachment: LinkAttachment
        let message: ZMConversationMessage
    }

    func configure(with object: Configuration, animated: Bool) {
        viewController.linkAttachment = object.attachment
        viewController.sourceMessage = object.message
        viewController.providerImage = UIImage(named: "soundcloud")
        viewController.fetchAttachment()
    }

}

class ConversationSoundCloudCellDescription<Player: PlayerViewControllerProtocol & UIViewController>: ConversationMessageCellDescription {
    typealias View = ConversationSoundCloudAttachmentCell<Player>
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 8

    let isFullWidth: Bool = true
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, attachment: LinkAttachment) {
        self.configuration = View.Configuration(attachment: attachment, message: message)
        actionController = nil
    }
}
