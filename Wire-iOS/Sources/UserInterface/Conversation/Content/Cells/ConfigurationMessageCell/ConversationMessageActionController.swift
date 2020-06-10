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
    
    enum Action: CaseIterable {
        case copy, reply, details, edit, delete, save, cancel, download, forward, like, unlike, resend, revealMessage
        
        var title: String {
            let key: String

            switch self {
            case .copy:
                key = "content.message.copy"
            case .reply:
                key = "content.message.reply"
            case .details:
                key = "content.message.details"
            case .edit:
                key = "message.menu.edit.title"
            case .delete:
                key = "content.message.delete"
            case .save:
                key = "content.message.save"
            case .cancel:
                key = "general.cancel"
            case .download:
                key = "content.message.download"
            case .forward:
                key = "content.message.forward"
            case .like:
                key = "content.message.like"
            case .unlike:
                key = "content.message.unlike"
            case .resend:
                key = "content.message.resend"
            case .revealMessage:
                key = "content.message.go_to_conversation"
            }
            
            return key.localized
        }
        
        var messageAction: MessageAction {
            switch self {
                
            case .copy:
                return .copy
            case .reply:
                return .reply
            case .details:
                return .openDetails
            case .edit:
                return .edit
            case .delete:
                return .delete
            case .save:
                return .save
            case .cancel:
                return .cancel
            case .download:
                return .download
            case .forward:
                return .forward
            case .like, .unlike:
                return .like
            case .resend:
                return .resend
            case .revealMessage:
                return .showInConversation
            }
        }
        
        var selector: Selector {
            switch self {
            case .copy:
                return #selector(ConversationMessageActionController.copyMessage)
            case .reply:
                return #selector(ConversationMessageActionController.quoteMessage)
            case .details:
                return #selector(ConversationMessageActionController.openMessageDetails)
            case .edit:
                return #selector(ConversationMessageActionController.editMessage)
            case .delete:
                return #selector(ConversationMessageActionController.deleteMessage)
            case .save:
                return #selector(ConversationMessageActionController.saveMessage)
            case .cancel:
                return #selector(ConversationMessageActionController.cancelDownloadingMessage)
            case .download:
                return #selector(ConversationMessageActionController.downloadMessage)
            case .forward:
                return #selector(ConversationMessageActionController.forwardMessage)
            case .like:
                return #selector(ConversationMessageActionController.likeMessage)
            case .unlike:
                return #selector(ConversationMessageActionController.unlikeMessage)
            case .resend:
                return #selector(ConversationMessageActionController.resendMessage)
            case .revealMessage:
                return #selector(ConversationMessageActionController.revealMessage)
            }
        }
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


    func actionHandler(action: Action) -> UIActionHandler {
        return {_ in
            self.perform(action: action.messageAction)
        }
    }

    // MARK: - List of Actions
    
    @available(iOS 13.0, *)
    func allMessageMenuElements() -> [UIAction] {
        return Action.allCases
            .filter() {
                self.canPerformAction(action:$0)
            }
            .map() {
            return UIAction(title: $0.title,
                            image: nil,
                            handler: self.actionHandler(action: $0))
        }
    }

    static var allMessageActions: [UIMenuItem] {
        return Action.allCases.map() {
            return UIMenuItem(title: $0.title, action: $0.selector)
        }
    }

    func canPerformAction(action: Action) -> Bool {
        switch action {
            
        case .copy:
            return message.canBeCopied
        case .reply:
            return message.canBeQuoted
        case .details:
            return message.areMessageDetailsAvailable
        case .edit:
            return message.canBeEdited
        case .delete:
            return message.canBeDeleted
        case .save:
            return message.canBeSaved
        case .cancel:
            return message.canCancelDownload
        case .download:
            return message.canCancelDownload
        case .forward:
            return message.canBeForwarded
        case .like:
            return message.canBeLiked && !message.liked
        case .unlike:
            return message.canBeLiked && message.liked
        case .resend:
            return message.canBeResent
        case .revealMessage:
            return context == .collection
        }
    }
    
    func canPerformAction(_ selector: Selector) -> Bool {
        guard let action = Action.allCases.first(where:{
                $0.selector == selector
        }) else { return false }
        
        return canPerformAction(action: action)
    }

    func makeAccessibilityActions() -> [UIAccessibilityCustomAction] {
        return ConversationMessageActionController.allMessageActions
            .filter { self.canPerformAction($0.action) }
            .map { menuItem in
                UIAccessibilityCustomAction(name: menuItem.title, target: self, selector: menuItem.action)
            }
    }

    func makePreviewActions() -> [UIPreviewAction] {
        return ConversationMessageActionController.allMessageActions
            .filter { self.canPerformAction($0.action) }
            .map { menuItem in
                UIPreviewAction(title: menuItem.title, style: .default) { [weak self] _, _ in
                    self?.perform(menuItem.action)
                }
            }
    }
    
    // MARK: - Single Tap Action
    
    func performSingleTapAction() {
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

    func performDoubleTapAction() {
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
