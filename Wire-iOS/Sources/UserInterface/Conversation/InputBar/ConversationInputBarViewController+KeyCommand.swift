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

extension ConversationInputBarViewController {

    private typealias Shortcut = L10n.Localizable.Conversation.InputBar.Shortcut

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = []

        commands.append(
            UIKeyCommand(action: #selector(commandReturnPressed),
                         input: "\r",
                         modifierFlags: .command,
                         discoverabilityTitle: Shortcut.send)
        )

        if UIDevice.current.userInterfaceIdiom == .pad {
            commands.append(
                UIKeyCommand(action: #selector(shiftReturnPressed),
                             input: "\r",
                             modifierFlags: .shift,
                             discoverabilityTitle: Shortcut.newline)
            )
        }

        if inputBar.isEditing {
            commands.append(
                UIKeyCommand(action: #selector(escapePressed),
                             input: UIKeyCommand.inputEscape,
                             modifierFlags: [],
                             discoverabilityTitle: Shortcut.cancelEditingMessage)
            )
        } else if inputBar.textView.text.isEmpty {
            commands.append(
                UIKeyCommand(action: #selector(upArrowPressed),
                             input: UIKeyCommand.inputUpArrow,
                             modifierFlags: [],
                             discoverabilityTitle: Shortcut.editLastMessage)
            )
        } else if let mentionsView = mentionsView as? UIViewController, !mentionsView.view.isHidden {
            commands.append(
                UIKeyCommand(action: #selector(upArrowPressedForMention),
                             input: UIKeyCommand.inputUpArrow,
                             modifierFlags: [],
                             discoverabilityTitle: Shortcut.choosePreviousMention)
            )

            commands.append(
                UIKeyCommand(action: #selector(downArrowPressedForMention),
                             input: UIKeyCommand.inputDownArrow,
                             modifierFlags: [],
                             discoverabilityTitle: Shortcut.chooseNextMention)
            )
        }

        return commands
    }

    @objc func upArrowPressedForMention() {
        mentionsView?.selectPreviousUser()
    }

    @objc func downArrowPressedForMention() {
        mentionsView?.selectNextUser()
    }

    @objc
    func commandReturnPressed() {
        sendText()
    }

    @objc
    func shiftReturnPressed() {
        guard let selectedTextRange = inputBar.textView.selectedTextRange else { return }

        inputBar.textView.replace(selectedTextRange, withText: "\n")
    }

    @objc
    private func upArrowPressed() {
        delegate?.conversationInputBarViewControllerEditLastMessage()
    }

    @objc
    func escapePressed() {
        endEditingMessageIfNeeded()
    }

}
