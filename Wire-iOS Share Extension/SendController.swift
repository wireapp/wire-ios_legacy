//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireShareEngine
import WireDataModel


typealias DegradationStrategyChoice = (DegradationStrategy) -> ()
typealias SendingStateCallback = (_ type: SendingState) -> Void


/// This enum specifies the current state of the sending progress and is passed
/// as a parameter in a `Progress` closure.
enum SendingState {
    case preparing // Some attachments need to be prepared, this case is not always invoked.
    case startingSending // The messages are about to be appended, the callback will always be invoked axecatly once.
    case sending(Float) // The progress of the sending operation.
    case conversationDidDegrade((Set<ZMUser>, DegradationStrategyChoice)) // In case the conversation degrades this case will be passed.
    case done // Sending either was cancelled (due to degradation for example) or finished.
}


/// This class encapsulates the preparation and sending of text an `NSItemProviders`.
/// It creates `UnsentSendable` instances and queries them if they need preparation.
/// If at least one of them does, it will call `prepare` on those who do before calling `send`.
/// During the sending procress the current state of the operation is reported through the passed in
/// `SendingCallState` in the `send` method. In comparison to the `PostContent` class, the `SendController`
/// itself has no knowledge about conversation degradation.
class SendController {

    private var observer: SendableBatchObserver? = nil
    private var isCancelled = false
    private var unsentSendables: [UnsentSendable]
    private weak var sharingSession: SharingSession?

    public var sentAllSendables = false

    init(text: String, attachments: [NSItemProvider], conversation: Conversation, sharingSession: SharingSession) {
        var sendables: [UnsentSendable] = attachments.flatMap {
            return UnsentImageSendable(conversation: conversation, sharingSession: sharingSession, attachment: $0)
                ?? UnsentFileSendable(conversation: conversation, sharingSession: sharingSession, attachment: $0)
        }

        if !text.isEmpty {
            sendables.insert(UnsentTextSendable(conversation: conversation, sharingSession: sharingSession, text: text), at: 0)
        }

        self.sharingSession = sharingSession
        unsentSendables = sendables
    }

    /// Send (and prepare if needed) the text and attachment items passed into the initializer.
    /// The passed in `SendingStateCallback` closure will be called multiple times with the current state of the operation.
    func send(progress: @escaping SendingStateCallback) {
        let completion: ([Sendable]) -> Void = { [weak self] sendables in
            guard let `self` = self else { return }
            self.observer = SendableBatchObserver(sendables: sendables)
            self.observer?.progressHandler = {
                progress(.sending($0))
            }

            self.observer?.sentHandler = { [weak self] in
                self?.sentAllSendables = true
                progress(.done)
            }
        }

        if unsentSendables.contains(where: { $0.needsPreparation }) {
            progress(.preparing)
            prepare(unsentSendables: unsentSendables) { [weak self] in
                guard let `self` = self else { return }
                guard !self.isCancelled else { return progress(.done) }
                progress(.startingSending)
                self.append(unsentSendables: self.unsentSendables, completion: completion)
            }
        } else {
            progress(.startingSending)
            append(unsentSendables: unsentSendables, completion: completion)
        }
    }

    /// Cancels the sending operation. In case the current state is preparing,
    /// a flag will be set to abort sending after the preparation is done.
    func cancel(completion: @escaping () -> Void) {
        isCancelled = true

        let sendablesToCancel = self.observer?.sendables.lazy.filter { !$0.isSent }

        sharingSession?.enqueue(changes: { 
            sendablesToCancel?.forEach {
                $0.cancel()
            }
        }, completionHandler: completion)
    }

    private func prepare(unsentSendables: [UnsentSendable], completion: @escaping () -> Void) {
        let preparationGroup = DispatchGroup()

        unsentSendables.filter { $0.needsPreparation }.forEach {
            preparationGroup.enter()
            $0.prepare {
                preparationGroup.leave()
            }
        }

        preparationGroup.notify(queue: .main, execute: completion)
    }

    private func append(unsentSendables: [UnsentSendable], completion: @escaping ([Sendable]) -> Void) {
        guard !isCancelled else { return completion([]) }
        let sendingGroup = DispatchGroup()
        var messages = [Sendable]()

        let appendToMessages: (Sendable?) -> Void = { sendable in
            defer { sendingGroup.leave() }
            guard let sendable = sendable else { return }
            messages.append(sendable)
        }

        unsentSendables.filter {
            $0.error != .unsupportedAttachment
        }.forEach {
            sendingGroup.enter()
            $0.send(completion: appendToMessages)
        }

        sendingGroup.notify(queue: .main) {
            completion(messages)
        }
    }

}
