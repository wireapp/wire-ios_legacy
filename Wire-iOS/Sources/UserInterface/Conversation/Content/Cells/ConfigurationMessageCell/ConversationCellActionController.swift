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

class ConversationCellActionController: NSObject {

    let message: ZMConversationMessage!
    weak var responder: MessageActionResponder?

    init(message: ZMConversationMessage, responder: MessageActionResponder) {
        self.message = message
        self.responder = responder
    }

    // MARK: - List of Actions

    func canPerformAction(selector: Selector) -> Bool {
        return false
    }

    func actions() -> [MessageAction] {
        return []
    }

    // MARK: - Handler

}

private let MessageActionCancelName = "MessageActionCancel"
private let MessageActionResendName = "MessageActionResend"
private let MessageActionDeleteName = "MessageActionDelete"
private let MessageActionPresentName = "MessageActionPresent"
private let MessageActionSaveName = "MessageActionSave"
private let MessageActionCopyName = "MessageActionCopy"
private let MessageActionEditName = "MessageActionEdit"
private let MessageActionSketchDrawName = "MessageActionSketchDraw"
private let MessageActionSketchEmojiName = "MessageActionSketchEmoji"
private let MessageActionSketchText = "MessageActionSketchText"
private let MessageActionLikeName = "MessageActionLike"
private let MessageActionForwardName = "MessageActionForward"
private let MessageActionShowInConversationName = "MessageActionShowInConversation"
private let MessageActionDownloadName = "MessageActionDownload"
private let MessageActionReplyName = "MessageActionReply"


extension MessageAction {

    init?(name: String) {
        switch name {
        case MessageActionCancelName: self = .cancel
        case MessageActionResendName: self = .resend
        case MessageActionDeleteName: self = .delete
        case MessageActionPresentName: self = .present
        case MessageActionSaveName: self = .save
        case MessageActionCopyName: self = .copy
        case MessageActionEditName: self = .edit
        case MessageActionSketchDrawName: self = .sketchDraw
        case MessageActionSketchEmojiName: self = .sketchEmoji
        case MessageActionSketchText: self = .sketchText
        case MessageActionLikeName: self = .like
        case MessageActionForwardName: self = .forward
        case MessageActionShowInConversationName: self = .showInConversation
        case MessageActionDownloadName: self = .download
        case MessageActionReplyName: self = .reply
        default: return nil
        }
    }

    var name: String {
        switch self {
        case .cancel: return MessageActionCancelName
        case .resend: return MessageActionResendName
        case .delete: return MessageActionDeleteName
        case .present: return MessageActionPresentName
        case .save: return MessageActionSaveName
        case .copy: return MessageActionCopyName
        case .edit: return MessageActionEditName
        case .sketchDraw: return MessageActionSketchDrawName
        case .sketchEmoji: return MessageActionSketchEmojiName
        case .sketchText: return MessageActionSketchText
        case .like: return MessageActionLikeName
        case .forward: return MessageActionForwardName
        case .showInConversation: return MessageActionShowInConversationName
        case .download: return MessageActionDownloadName
        case .reply: return MessageActionReplyName
        }
    }

}
