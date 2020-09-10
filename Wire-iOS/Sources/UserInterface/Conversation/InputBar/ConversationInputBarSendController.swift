// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import WireDataModel
import UIKit
import WireSyncEngine

final class ConversationInputBarSendController: NSObject {
    let conversation: ZMConversation
    private let feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    @objc
    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init()
    }

    func sendMessage(withImageData imageData: Data, completion completionHandler: Completion? = nil) {
        feedbackGenerator.prepare()
        ZMUserSession.shared()?.enqueue({
            do {
                try self.conversation.appendImage(from:imageData)
                self.feedbackGenerator.impactOccurred()
            } catch {
                Logging.messageProcessing.warn("Failed to append image message. Reason: \(error.localizedDescription)")
            }
        }, completionHandler: {
                completionHandler?()
            Analytics.shared().tagMediaActionCompleted(.photo, inConversation: self.conversation)
        })
    }
    
    func sendTextMessage(_ text: String,
                         mentions: [Mention],
                         replyingTo message: ZMConversationMessage?) {
        ZMUserSession.shared()?.enqueue({
            let shouldFetchLinkPreview = !Settings.disableLinkPreviews

            do {
                try self.conversation.appendText(content:text, mentions: mentions, replyingTo: message, fetchLinkPreview: shouldFetchLinkPreview)
                self.conversation.draftMessage = nil
            } catch {
                Logging.messageProcessing.warn("Failed to append text message. Reason: \(error.localizedDescription)")
            }
        }, completionHandler: {
            Analytics.shared().tagMediaActionCompleted(.text, inConversation: self.conversation)
            
        })
    }
    
    func sendTextMessage(_ text: String, mentions: [Mention], withImageData data: Data) {
        let shouldFetchLinkPreview = !Settings.disableLinkPreviews
        
        ZMUserSession.shared()?.enqueue({
            do {
                try self.conversation.appendText(content: text, mentions: mentions, replyingTo: nil, fetchLinkPreview: shouldFetchLinkPreview)
                try self.conversation.appendImage(from: data)
                self.conversation.draftMessage = nil
            } catch {
                Logging.messageProcessing.warn("Failed to append text message with image data. Reason: \(error.localizedDescription)")
            }
        }, completionHandler: {
            Analytics.shared().tagMediaActionCompleted(.photo, inConversation: self.conversation)
            Analytics.shared().tagMediaActionCompleted(.text, inConversation: self.conversation)
        })
    }
}
