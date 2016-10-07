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
        ephemeralKeyboardViewController = EphemeralKeyboardViewController()
        ephemeralKeyboardViewController?.delegate = self
        guard let timeout = conversation.destructionTimout else { return }
        ephemeralKeyboardViewController?.setSelection(timeout)
    }

    public func configureHourglassButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(hourglassButtonPressed), for: .touchUpInside)
    }

    public func hourglassButtonPressed(_ sender: IconButton) {
        if mode != .timeoutConfguration {
            mode = .timeoutConfguration
            inputBar.textView.becomeFirstResponder()
        } else {
            mode = .textInput
        }
    }

}

extension ConversationInputBarViewController: EphemeralKeyboardViewControllerDelegate {

    func ephemeralKeyboard(_ keyboard: EphemeralKeyboardViewController, didSelectMessageTimeout timeout: ZMConversationMessageDestructionTimeout) {
        ZMUserSession.shared().enqueueChanges {
            self.conversation.updateMessageDestructionTimeout(timeout)
        }
    }

}

private extension ZMConversation {

    var destructionTimout: ZMConversationMessageDestructionTimeout? {
        return ZMConversationMessageDestructionTimeout(rawValue: Int16(messageDestructionTimeout))
    }

}
