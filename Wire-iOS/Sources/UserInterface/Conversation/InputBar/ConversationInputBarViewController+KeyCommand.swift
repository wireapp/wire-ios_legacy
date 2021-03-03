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

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = []

        commands.append(UIKeyCommand(input: "\r", modifierFlags: .command, action: #selector(commandReturnPressed), discoverabilityTitle: "conversation.input_bar.shortcut.send".localized))

        if UIDevice.current.userInterfaceIdiom == .pad {
            commands.append(UIKeyCommand(input: "\r", modifierFlags: .shift, action: #selector(shiftReturnPressed), discoverabilityTitle: "conversation.input_bar.shortcut.newline".localized))
        }

        if inputBar.isEditing {
            commands.append(UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapePressed), discoverabilityTitle: "conversation.input_bar.shortcut.cancel_editing_message".localized))
        } else if inputBar.textView.text.count == 0 {
            commands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(upArrowPressed), discoverabilityTitle: "conversation.input_bar.shortcut.edit_last_message".localized))
        } else if let mentionsView = mentionsView as? UIViewController, !mentionsView.view.isHidden {
            // TODO: string rsc
            commands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(upArrowPressedForMention), discoverabilityTitle: "conversation.input_bar.shortcut.choosePreviousMention".localized))
            // TODO: string rsc
            commands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(downArrowPressedForMention), discoverabilityTitle: "conversation.input_bar.shortcut.chooseNextMention".localized))

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
    func upArrowPressed() {
        delegate?.conversationInputBarViewControllerEditLastMessage()
    }

    @objc
    func escapePressed() {
        endEditingMessageIfNeeded()
    }

}
