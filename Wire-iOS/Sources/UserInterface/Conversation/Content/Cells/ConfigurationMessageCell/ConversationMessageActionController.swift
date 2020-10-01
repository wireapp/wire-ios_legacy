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
import WireCommonComponents

final class ConversationMessageActionController {

    enum Context: Int {
        case content, collection
    }

    let message: ZMConversationMessage
    let context: Context
    weak var responder: MessageActionResponder?
    weak var view: UIView!

    init(responder: MessageActionResponder?,
         message: ZMConversationMessage,
         context: Context,
         view: UIView) {
        self.responder = responder
        self.message = message
        self.context = context
        self.view = view
    }

    // MARK: - List of Actions

    private var allPerformableMessageAction: [MessageAction] {
        return MessageAction.allCases
            .filter(canPerformAction)
    }

    @available(iOS 13.0, *)
    func allMessageMenuElements() -> [UIAction] {
        weak var responder = self.responder
        weak var message = self.message
        unowned let targetView: UIView = self.view

        return allPerformableMessageAction.compactMap { messageAction in
            guard let title = messageAction.title else { return nil }

            let handler: UIActionHandler = { _ in
                responder?.perform(action: messageAction,
                                   for: message,
                                   view: targetView)
            }
            
            return UIAction(title: title,
                            image: messageAction.systemIcon(),
                            handler: handler)
        }
    }

    // MARK: - UI menu

    static var allMessageActions: [UIMenuItem] {
        return MessageAction.allCases.compactMap {
            guard let selector = $0.selector,
                  let title = $0.title else { return nil }
            return UIMenuItem(title: title, action: selector)
        }
    }

    func canPerformAction(action: MessageAction) -> Bool {
        switch action {
        case .copy:
            return message.canBeCopied
        case .digitallySign:
            return message.canBeDigitallySigned
        case .reply:
            return message.canBeQuoted
        case .openDetails:
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
            return message.canBeDownloaded
        case .forward:
            return message.canBeForwarded
        case .like:
            return message.canBeLiked && !message.liked
        case .unlike:
            return message.canBeLiked && message.liked
        case .resend:
            return message.canBeResent
        case .showInConversation:
            return context == .collection
        case .sketchDraw,
             .sketchEmoji:
            return message.isImage
        case .present,
             .openQuote:
            return false
        }
    }

    func canPerformAction(_ selector: Selector) -> Bool {
        guard let action = MessageAction.allCases.first(where: {
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

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    var previewActionItems: [UIPreviewAction] {
        return allPerformableMessageAction.compactMap { messageAction in
            guard let title = messageAction.title else { return nil }

            return UIPreviewAction(title: title,
                                   style: .default) { [weak self] _, _ in
                                    self?.perform(action: messageAction)
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
        responder?.perform(action: action,
                           for: message,
                           view: view)
    }

    @objc func digitallySignMessage() {
        perform(action: .digitallySign)
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
