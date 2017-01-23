//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import UIKit
import WireExtensionComponents
import WireShareEngine
import MobileCoreServices


/// Content that is shared on a share extension post attempt
class PostContent {
    
    /// Conversation to post to
    var target: Conversation? = nil

    fileprivate var sendController: SendController?

    var sentAllSendables: Bool {
        guard let sendController = sendController else { return false }
        return sendController.sentAllSendables
    }
    
    /// List of attachments to post
    var attachments : [NSItemProvider]
    
    init(attachments: [NSItemProvider]) {
        self.attachments = attachments
    }

}


// MARK: - Send attachments

/// What to do when a conversation that was verified degraded (we discovered a new
/// non-verified client)
enum DegradationStrategy {
    case sendAnyway
    case cancelSending
}


extension PostContent {

    /// Send the content to the selected conversation
    func send(text: String, sharingSession: SharingSession, progress: @escaping Progress) {
        let conversation = target!
        sendController = SendController(text: text, attachments: attachments, conversation: conversation, sharingSession: sharingSession)

        let allMessagesEnqueuedGroup = DispatchGroup()
        allMessagesEnqueuedGroup.enter()

        let conversationObserverToken = conversation.add { change in
            // make sure that we notify only when we are done preparing all the ones to be sent
            allMessagesEnqueuedGroup.notify(queue: .main, execute: {
                let degradationStrategy: DegradationStrategyChoice = {
                    switch $0 {
                    case .sendAnyway:
                        conversation.resendMessagesThatCausedConversationSecurityDegradation()
                    case .cancelSending:
                        conversation.doNotResendMessagesThatCausedDegradation()
                        progress(.done)
                    }
                }
                progress(.conversationDidDegrade((change.users, degradationStrategy)))
            })
        }

        sendController?.send {
            switch $0 {
            case .done: conversationObserverToken.tearDown()
            case .startingSending: allMessagesEnqueuedGroup.leave()
            default: break
            }

            progress($0)
        }
    }

    func cancel(completion: @escaping () -> Void) {
        sendController?.cancel(completion: completion)
    }

}
