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
import UIKit
import WireDataModel

final class ConversationCallController: NSObject {

    private unowned let target: UIViewController
    private let conversation: ZMConversation

    init(conversation: ZMConversation, target: UIViewController) {
        self.conversation = conversation
        self.target = target
        super.init()
    }

    func startAudioCall(started: (() -> Void)?) {
        let startCall = { [weak self] in
            guard let `self` = self else { return }
            self.conversation.confirmJoiningCallIfNeeded(alertPresenter: self.target) {
                started?()
                self.conversation.startAudioCall()
            }
        }

        if conversation.localParticipants.count <= 4 {
            startCall()
        } else {
            confirmGroupCall {[weak self] accepted in
                self?.target.setNeedsStatusBarAppearanceUpdate()

                guard accepted else { return }
                startCall()
            }
        }
    }

    func startVideoCall(started: (() -> Void)?) {
        conversation.confirmJoiningCallIfNeeded(alertPresenter: target) { [conversation] in
            started?()
            conversation.startVideoCall()
        }
    }

    func joinCall() {
        guard conversation.canJoinCall else { return }
        conversation.confirmJoiningCallIfNeeded(alertPresenter: target) { [conversation] in
            conversation.joinCall() // This will result in joining an ongoing call.
        }
    }

    // MARK: - Helper

    private func confirmGroupCall(completion: @escaping (_ completion: Bool) -> Void) {
        let controller = UIAlertController.confirmGroupCall(
            participants: conversation.localParticipants.count - 1,
            completion: completion
        )

        target.present(controller, animated: true)
    }

}
