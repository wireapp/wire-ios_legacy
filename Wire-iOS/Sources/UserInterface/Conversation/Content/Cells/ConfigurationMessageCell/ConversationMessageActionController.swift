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

@objc class ConversationMessageActionController: NSObject {

    @objc(ConversationMessageActionControllerContext)
    enum Context: Int {
        case content, collection
    }

    @objc let message: ZMConversationMessage
    @objc let context: Context
    @objc weak var responder: MessageActionResponder?

    @objc init(responder: MessageActionResponder?, message: ZMConversationMessage, context: Context) {
        self.responder = responder
        self.message = message
        self.context = context
    }

    // MARK: - List of Actions

    @objc static let allMessageActions: [UIMenuItem] = [
        UIMenuItem(title: "content.message.copy".localized, action: #selector(ConversationMessageActionController.copyMessage)),
        UIMenuItem(title: "content.message.reply".localized, action: #selector(ConversationMessageActionController.quoteMessage)),
        UIMenuItem(title: "content.message.details".localized, action: #selector(ConversationMessageActionController.openMessageDetails)),
        UIMenuItem(title: "message.menu.edit.title".localized, action: #selector(ConversationMessageActionController.editMessage)),
        UIMenuItem(title: "content.message.delete".localized, action: #selector(ConversationMessageActionController.deleteMessage)),
        UIMenuItem(title: "content.message.save".localized, action: #selector(ConversationMessageActionController.saveMessage)),
        UIMenuItem(title: "general.cancel".localized, action: #selector(ConversationMessageActionController.cancelDownloadingMessage)),
        UIMenuItem(title: "content.message.download".localized, action: #selector(ConversationMessageActionController.downloadMessage)),
        UIMenuItem(title: "content.message.forward".localized, action: #selector(ConversationMessageActionController.forwardMessage)),
        UIMenuItem(title: "content.message.like".localized, action: #selector(ConversationMessageActionController.likeMessage)),
        UIMenuItem(title: "content.message.unlike".localized, action: #selector(ConversationMessageActionController.unlikeMessage)),
        UIMenuItem(title: "content.message.resend".localized, action: #selector(ConversationMessageActionController.resendMessage)),
        UIMenuItem(title: "content.message.go_to_conversation".localized, action: #selector(ConversationMessageActionController.revealMessage))
    ]

    @objc func canPerformAction(_ selector: Selector) -> Bool {
        switch selector {
        case #selector(ConversationMessageActionController.copyMessage):
            return message.canBeCopied
        case #selector(ConversationMessageActionController.editMessage):
            return message.canBeEdited
        case #selector(ConversationMessageActionController.quoteMessage):
            return message.canBeQuoted
        case #selector(ConversationMessageActionController.openMessageDetails):
            return message.areMessageDetailsAvailable
        case #selector(ConversationMessageActionController.cancelDownloadingMessage):
            return message.canCancelDownload
        case #selector(ConversationMessageActionController.downloadMessage):
            return message.canBeDownloaded
        case #selector(ConversationMessageActionController.saveMessage):
            return message.canBeSaved
        case #selector(ConversationMessageActionController.forwardMessage):
            return message.canBeForwarded
        case #selector(ConversationMessageActionController.likeMessage):
            return message.canBeLiked && !message.liked
        case #selector(ConversationMessageActionController.unlikeMessage):
            return message.canBeLiked && message.liked
        case #selector(ConversationMessageActionController.deleteMessage):
            return message.canBeDeleted
        case #selector(ConversationMessageActionController.resendMessage):
            return message.canBeResent
        case #selector(ConversationMessageActionController.revealMessage):
            return context == .collection
        default:
            return false
        }
    }

    @objc func makeAccessibilityActions() -> [UIAccessibilityCustomAction] {
        return ConversationMessageActionController.allMessageActions
            .filter { self.canPerformAction($0.action) }
            .map { menuItem in
                UIAccessibilityCustomAction(name: menuItem.title, target: self, selector: menuItem.action)
            }
    }

    @objc func makePreviewActions() -> [UIPreviewAction] {
        return ConversationMessageActionController.allMessageActions
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
    
    var singleTapAction: MessageAction? {
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

    // MARK: - Double Tap Action

    @objc func performDoubleTapAction() {
        guard let doubleTapAction = doubleTapAction else { return }
        responder?.wants(toPerform: doubleTapAction, for: message)
    }

    var doubleTapAction: MessageAction? {
        return message.canBeLiked ? .like : nil
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

    @objc func openMessageDetails() {
        responder?.wants(toPerform: .openDetails, for: message)
    }

    @objc func cancelDownloadingMessage() {
        responder?.wants(toPerform: .cancel, for: message)
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

    @objc func revealMessage() {
        responder?.wants(toPerform: .showInConversation, for: message)
    }

}
