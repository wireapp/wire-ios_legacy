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
import WireDataModel

final class ConversationMessageActionController: NSObject {

    enum Context: Int {
        case content, collection
    }

    let message: ZMConversationMessage
    let context: Context
    weak var responder: MessageActionResponder?
    weak var view: UIView!

    init(responder: MessageActionResponder?, message: ZMConversationMessage, context: Context, view: UIView) {
        self.responder = responder
        self.message = message
        self.context = context
        self.view = view
    }


    // MARK: - List of Actions

    static let allMessageActions: [UIMenuItem] = [
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

        perform(action: singleTapAction)
    }
    
    var singleTapAction: MessageAction? {
        if message.isImage, message.imageMessageData?.isDownloaded == true {
            return .present
        } else if message.isFile, !message.isAudio, let transferState = message.fileMessageData?.transferState {
            switch transferState {
            case .uploaded:
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
        perform(action: doubleTapAction)
    }

    var doubleTapAction: MessageAction? {
        return message.canBeLiked ? .like : nil
    }

    // MARK: - Handler

    private func perform(action: MessageAction) {
        responder?.perform(action: action, for: message, view: view)
    }

    @objc func copyMessage() {
        perform(action: .copy)
    }

    @objc func editMessage() {
        perform(action: .edit)
    }
    
    @objc func quoteMessage() {
        perform(action: .reply)
    }

    @objc func openMessageDetails() {
        perform(action: .openDetails)
    }

    @objc func cancelDownloadingMessage() {
        perform(action: .cancel)
    }

    @objc func downloadMessage() {
        perform(action: .download)
    }
    
    @objc func saveMessage() {
        perform(action: .save)
    }

    @objc func forwardMessage() {
        perform(action: .forward)
    }
    
    @objc func likeMessage() {
        perform(action: .like)
    }

    @objc func unlikeMessage() {
        perform(action: .like)
    }
    
    @objc func deleteMessage() {
        perform(action: .delete)
    }
    
    @objc func resendMessage() {
        perform(action: .resend)
    }

    @objc func revealMessage() {
        perform(action: .showInConversation)
    }

}
