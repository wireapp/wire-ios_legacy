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


extension ConversationInputBarViewController {

    public func createEphemeralKeyboardViewController() {
        ephemeralKeyboardViewController = EphemeralKeyboardViewController(conversation: conversation)
        ephemeralKeyboardViewController?.delegate = self
    }

    public func configureHourglassButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(hourglassButtonPressed), for: .touchUpInside)
    }

    public func hourglassButtonPressed(_ sender: IconButton) {
        dismissEphemeralKeyboard()
    }

    fileprivate func dismissEphemeralKeyboard() {
        if mode != .timeoutConfguration {
            mode = .timeoutConfguration
            inputBar.textView.becomeFirstResponder()
        } else {
            mode = .textInput
        }
    }

    public func updateWritingState() {
        guard nil == editingMessage else { return }
        inputBar.inputBarState = .writing(ephemeral: conversation.destructionEnabled)
    }

    public func updateEphemeralSendButtonTitle(_ button: ButtonWithLargerHitArea) {
        let title = conversation.destructionTimeout.shortDisplayString
        button.setTitle(title, for: .normal)
    }

}

extension ConversationInputBarViewController: EphemeralKeyboardViewControllerDelegate {

    func ephemeralKeyboardWantsToBeDismissed(_ keyboard: EphemeralKeyboardViewController) {
        dismissEphemeralKeyboard()
    }

    func ephemeralKeyboard(_ keyboard: EphemeralKeyboardViewController, didSelectMessageTimeout timeout: ZMConversationMessageDestructionTimeout) {
        inputBar.inputBarState = .writing(ephemeral: timeout != .none)
        ZMUserSession.shared().enqueueChanges {
            self.conversation.updateMessageDestructionTimeout(timeout)
        }
    }

}

public extension ZMConversation {

    var destructionEnabled: Bool {
        return destructionTimeout != .none
    }

    var destructionTimeout: ZMConversationMessageDestructionTimeout {
        return ZMConversationMessageDestructionTimeout(rawValue: Int16(messageDestructionTimeout)) ?? .none
    }

}
