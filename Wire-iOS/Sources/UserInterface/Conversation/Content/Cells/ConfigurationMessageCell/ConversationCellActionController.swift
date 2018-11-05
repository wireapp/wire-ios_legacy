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

@objc class ConversationCellActionController: NSObject {

    let message: ZMConversationMessage
    weak var responder: MessageActionResponder?

    @objc init(responder: MessageActionResponder?, message: ZMConversationMessage) {
        self.responder = responder
        self.message = message
    }

    // MARK: - Rules

    private let replyPredicate: (ZMConversationMessage) -> Bool = { message in
        return !message.isSystem && !message.isKnock
    }

    // MARK: - List of Actions

    static let allMessageActions: [UIMenuItem] = [
        UIMenuItem(title: "Copy", action: #selector(ConversationCellActionController.copyMessage)),
        UIMenuItem(title: "Save", action: #selector(ConversationCellActionController.saveMessage)),
        UIMenuItem(title: "Download", action: #selector(ConversationCellActionController.downloadMessage)),
        UIMenuItem(title: "Like", action: #selector(ConversationCellActionController.likeMessage)),
        UIMenuItem(title: "Reply", action: #selector(ConversationCellActionController.replyToMessage)),
        UIMenuItem(title: "Share", action: #selector(ConversationCellActionController.replyToMessage)),
        UIMenuItem(title: "Delete", action: #selector(ConversationCellActionController.deleteMessage)),
        UIMenuItem(title: "Resend", action: #selector(ConversationCellActionController.resendMessage)),
        UIMenuItem(title: "Open", action: #selector(ConversationCellActionController.openMessage))
    ]

    func canPerformAction(_ selector: Selector) -> Bool {
        switch selector {
        case #selector(ConversationCellActionController.copyMessage):
            return message.canBeCopied
        case #selector(ConversationCellActionController.deleteMessage):
            return message.canBeDeleted
        case #selector(ConversationCellActionController.replyToMessage):
            return message.canBeQuoted
        case #selector(ConversationCellActionController.likeMessage):
            return message.canBeLiked
        case #selector(ConversationCellActionController.saveMessage):
            return true
        case #selector(ConversationCellActionController.downloadMessage):
            return true
        default:
            return false
        }
    }

    // MARK: - Handler

    @objc func copyMessage() {
        responder?.wants(toPerform: .copy, for: message)
    }

    @objc func likeMessage() {
        responder?.wants(toPerform: .like, for: message)
    }

    @objc func deleteMessage() {
        responder?.wants(toPerform: .delete, for: message)
    }

    @objc func replyToMessage() {
        responder?.wants(toPerform: .reply, for: message)
    }

    @objc func saveMessage() {
        responder?.wants(toPerform: .save, for: message)
    }

    @objc func downloadMessage() {
        responder?.wants(toPerform: .download, for: message)
    }

    @objc func resendMessage() {
        responder?.wants(toPerform: .resend, for: message)
    }

    @objc func openMessage() {
        responder?.wants(toPerform: .present, for: message)
    }

}
