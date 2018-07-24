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

import Foundation

@objcMembers final public class ConversationCallController: NSObject {
    
    private unowned let target: UIViewController
    private let conversation: ZMConversation
    
    @objc public init(conversation: ZMConversation, target: UIViewController) {
        self.conversation = conversation
        self.target = target
        super.init()
    }
    
    @objc public func startAudioCall(started: (() -> Void)?) {
        let startCall = { [weak self] in
            guard let `self` = self else { return }
            self.confirmStartingCallIfNeeded {
                started?()
                self.conversation.startAudioCall()
            }
        }
        
        if conversation.activeParticipants.count <= 4 {
            startCall()
        } else {
            confirmGroupCall { accepted in
                guard accepted else { return }
                startCall()
            }
        }
    }
    
    @objc public func startVideoCall(started: (() -> Void)?) {
        confirmStartingCallIfNeeded { [conversation] in
            started?()
            conversation.startVideoCall()
        }
    }
    
    @objc public func joinCall() {
        guard conversation.canJoinCall else { return }
        conversation.confirmJoiningCallIfNeeded(alertPresenter: target) { [conversation] in
            conversation.joinCall() // This will result in joining an ongoing call.
        }
    }
    
    // MARK: - Helper
    
    private func confirmStartingCallIfNeeded(completion: @escaping () -> Void) {
        guard true == ZMUserSession.shared()?.isCallOngoing else { return completion() }
        let controller = UIAlertController.ongoingCallStartCallConfirmation { confirmed in
            guard confirmed else { return }
            ZMUserSession.shared()?.callCenter?.endAllCalls()
            completion()
        }
        target.present(controller, animated: true)
    }

    private func confirmGroupCall(completion: @escaping (_ completion: Bool) -> ()) {
        let controller = UIAlertController.confirmGroupCall(
            participants: conversation.activeParticipants.count - 1,
            completion: completion
        )
        target.present(controller, animated: true)
    }

}
