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

    // MARK: - List of Actions

    @objc static let allMessageActions: [UIMenuItem] = [
        UIMenuItem(title: "content.message.copy".localized, action: #selector(ConversationCellActionController.copyMessage)),
        UIMenuItem(title: "content.message.reply".localized, action: #selector(ConversationCellActionController.quoteMessage)),
        UIMenuItem(title: "message.menu.edit.title".localized, action: #selector(ConversationCellActionController.editMessage)),
        UIMenuItem(title: "content.message.delete".localized, action: #selector(ConversationCellActionController.deleteMessage)),
        UIMenuItem(title: "content.message.save".localized, action: #selector(ConversationCellActionController.saveMessage)),
        UIMenuItem(title: "content.message.download".localized, action: #selector(ConversationCellActionController.downloadMessage)),
        UIMenuItem(title: "content.message.forward".localized, action: #selector(ConversationCellActionController.forwardMessage)),
        UIMenuItem(title: "content.message.like".localized, action: #selector(ConversationCellActionController.likeMessage)),
        UIMenuItem(title: "content.message.unlike".localized, action: #selector(ConversationCellActionController.unlikeMessage)),
        UIMenuItem(title: "content.message.resend".localized, action: #selector(ConversationCellActionController.resendMessage))
    ]

    @objc func canPerformAction(_ selector: Selector) -> Bool {
        switch selector {
        case #selector(ConversationCellActionController.copyMessage):
            return message.canBeCopied
        case #selector(ConversationCellActionController.editMessage):
            return message.canBeEdited
        case #selector(ConversationCellActionController.quoteMessage):
            return message.canBeQuoted
        case #selector(ConversationCellActionController.downloadMessage):
            return message.canBeDownloaded
        case #selector(ConversationCellActionController.saveMessage):
            return message.canBeSaved
        case #selector(ConversationCellActionController.forwardMessage):
            return message.canBeForwarded
        case #selector(ConversationCellActionController.likeMessage):
            return message.canBeLiked && !message.liked
        case #selector(ConversationCellActionController.unlikeMessage):
            return message.canBeLiked && message.liked
        case #selector(ConversationCellActionController.deleteMessage):
            return message.canBeDeleted
        case #selector(ConversationCellActionController.resendMessage):
            return message.canBeResent
        default:
            return false
        }
    }

    @objc func makePreviewActions() -> [UIPreviewAction] {
        return ConversationCellActionController.allMessageActions
            .filter { self.canPerformAction($0.action) }
            .map { menuItem in
                UIPreviewAction(title: menuItem.title, style: .default) { [weak self] _, _ in
                    self?.perform(menuItem.action)
                }
            }
    }
    
    // MARK: - Single Tap Action
    
    @objc func performSingleTapAction() {
        guard let singleTapAction = singleTapAction else { return }
        
        responder?.wants(toPerform: singleTapAction, for: message)
    }
    
    internal var singleTapAction: MessageAction? {
        if message.isImage, message.imageMessageData?.isDownloaded == true {
            return .present
        } else if message.isFile, !message.isAudio, let transferState = message.fileMessageData?.transferState {
            switch transferState {
            case .downloaded, .uploaded, .failedDownload:
                return .present
            default:
                return nil
            }
        }
        
        return nil
    }

    // MARK: - Handler

    @objc func copyMessage() {
        responder?.wants(toPerform: .copy, for: message)
    }

    @objc func editMessage() {
        responder?.wants(toPerform: .edit, for: message)
    }
    
    @objc func quoteMessage() {
        responder?.wants(toPerform: .reply, for: message)
    }

    @objc func downloadMessage() {
        responder?.wants(toPerform: .download, for: message)
    }
    
    @objc func saveMessage() {
        responder?.wants(toPerform: .save, for: message)
    }

    @objc func forwardMessage() {
        responder?.wants(toPerform: .forward, for: message)
    }
    
    @objc func likeMessage() {
        responder?.wants(toPerform: .like, for: message)
    }
    
    @objc func unlikeMessage() {
        responder?.wants(toPerform: .like, for: message)
    }
    
    @objc func deleteMessage() {
        responder?.wants(toPerform: .delete, for: message)
    }
    
    @objc func resendMessage() {
        responder?.wants(toPerform: .resend, for: message)
    }

}
