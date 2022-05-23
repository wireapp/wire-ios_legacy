//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireCommonComponents
import UIKit

enum MessageAction: CaseIterable {
    case
    digitallySign,
    copy,
    reply,
    openDetails,
    edit,
    delete,
    save,
    cancel,
    download,
    forward,
    like,
    unlike,
    resend,
    showInConversation,
    sketchDraw,
    sketchEmoji,
    // Not included in ConversationMessageActionController.allMessageActions, for image viewer/open quote
    present,
    openQuote,
    resetSession

    var title: String? {
        let key: String?

        switch self {
        case .copy:
            key = "content.message.copy"
        case .digitallySign:
            key = "content.message.sign"
        case .reply:
            key = "content.message.reply"
        case .openDetails:
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
        case .showInConversation:
            key = "content.message.go_to_conversation"
        case .sketchDraw:
            key = "image.add_sketch"
        case .sketchEmoji:
            key = "image.add_emoji"
        case .present,
             .openQuote,
             .resetSession:
            key = nil
        }

        return key?.localized
    }

    var icon: StyleKitIcon? {
        switch self {
        case .copy:
            return .copy
        case .reply:
            return .reply
        case .openDetails:
            return .about
        case .edit:
            return .pencil
        case .delete:
            return .trash
        case .save:
            return .save
        case .cancel:
            return .cross
        case .download:
            return .downArrow
        case .forward:
            return .export
        case .like:
            return .liked
        case .unlike:
            return .like
        case .resend:
            return .redo
        case .showInConversation:
            return .eye
        case .sketchDraw:
            return .brush
        case .sketchEmoji:
            return .emoji
        case .present,
             .openQuote,
             .digitallySign,
             .resetSession:
            return nil
        }
    }

    @available(iOS 13.0, *)
    func systemIcon() -> UIImage? {
        return imageSystemName().flatMap(UIImage.init(systemName:))
    }

    @available(iOS 13.0, *)
    private func imageSystemName() -> String? {
        let imageName: String?
        switch self {
        case .copy:
            imageName = "doc.on.doc"
        case .reply:
            imageName = "arrow.uturn.left"
        case .openDetails:
            imageName = "info.circle"
        case .edit:
            imageName = "pencil"
        case .delete:
            imageName = "trash"
        case .save:
            imageName = "arrow.down.to.line"
        case .cancel:
            imageName = "xmark"
        case .download:
            imageName = "chevron.down"
        case .forward:
            imageName = "square.and.arrow.up"
        case .like:
            imageName = "suit.heart"
        case .unlike:
            imageName = "suit.heart.fill"
        case .resend:
            imageName = "arrow.clockwise"
        case .showInConversation:
            imageName = "eye.fill"
        case .sketchDraw:
            imageName = "scribble"
        case .sketchEmoji:
            imageName = "smiley.fill"
        case .present,
             .openQuote,
             .digitallySign,
             .resetSession:
            imageName = nil
        }

        return imageName
    }

    var selector: Selector? {
        switch self {
        case .copy:
            return #selector(ConversationMessageActionController.copyMessage)
        case .digitallySign:
            return #selector(ConversationMessageActionController.digitallySignMessage)
        case .reply:
            return #selector(ConversationMessageActionController.quoteMessage)
        case .openDetails:
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
        case .showInConversation:
            return #selector(ConversationMessageActionController.revealMessage)
        case .present,
             .sketchDraw,
             .sketchEmoji,
             .openQuote,
             .resetSession:
            // no message related actions are not handled in ConversationMessageActionController
            return nil
        }
    }

    var accessibilityLabel: String? {
        switch self {
        case .copy:
            return "copy"
        case .save:
            return "save"
        case .sketchDraw:
            return "sketch over image"
        case .sketchEmoji:
            return "sketch emoji over image"
        case .showInConversation:
            return "reveal in conversation"
        case .delete:
            return "delete"
        case .unlike:
            return "unlike"
        case .like:
            return "like"
        default:
            return nil
        }
    }
}
