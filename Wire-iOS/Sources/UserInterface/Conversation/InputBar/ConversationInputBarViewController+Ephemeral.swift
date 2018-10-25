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

    @objc public func createEphemeralKeyboardViewController() {
        ephemeralKeyboardViewController = EphemeralKeyboardViewController(conversation: conversation)
        ephemeralKeyboardViewController?.delegate = self
    }

    @objc public func configureEphemeralKeyboardButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(ephemeralKeyboardButtonTapped), for: .touchUpInside)
    }

    @objc public func ephemeralKeyboardButtonTapped(_ sender: IconButton) {
        updateEphemeralKeyboardVisibility()
    }

    fileprivate func updateEphemeralKeyboardVisibility() {

        let showPopover = traitCollection.horizontalSizeClass == .regular
        let noPopoverPresented = presentedViewController == nil
        let regularNotPresenting = showPopover && noPopoverPresented
        let compactNotPresenting = mode != .timeoutConfguration && !showPopover

        // presenting
        if compactNotPresenting || regularNotPresenting {
            if showPopover {
                presentEphemeralControllerAsPopover()
            } else {
                // we only want to change the mode when we present a custom keyboard
                mode = .timeoutConfguration
                inputBar.textView.becomeFirstResponder()
            }
        // dismissing
        } else {
            if noPopoverPresented {
                mode = .textInput
            } else {
                ephemeralKeyboardViewController?.dismiss(animated: true, completion: nil)
                ephemeralKeyboardViewController = nil
            }
        }
    }
    
    private func presentEphemeralControllerAsPopover() {
        createEphemeralKeyboardViewController()
        ephemeralKeyboardViewController?.modalPresentationStyle = .popover
        ephemeralKeyboardViewController?.preferredContentSize = CGSize.IPadPopover.pickerSize
        let pointToView = ephemeralIndicatorButton.isHidden ? hourglassButton : ephemeralIndicatorButton

        if let popover = ephemeralKeyboardViewController?.popoverPresentationController,
            let presentInView = self.parent?.view,
            let backgroundColor = ephemeralKeyboardViewController?.view.backgroundColor {
                popover.config(from: self,
                           pointToView: pointToView,
                           sourceView: presentInView)

            popover.backgroundColor = backgroundColor
            popover.permittedArrowDirections = .down
        }

        guard let controller = ephemeralKeyboardViewController else { return }
        self.parent?.present(controller, animated: true)
    }

    @objc public func updateEphemeralIndicatorButtonTitle(_ button: ButtonWithLargerHitArea) {
        guard let timerValue = conversation.destructionTimeout else {
            button.setTitle("", for: .normal)
            return
        }
        
        let title = timerValue.shortDisplayString
        button.setTitle(title, for: .normal)
    }

}

extension ConversationInputBarViewController: EphemeralKeyboardViewControllerDelegate {

    @objc func ephemeralKeyboardWantsToBeDismissed(_ keyboard: EphemeralKeyboardViewController) {
        updateEphemeralKeyboardVisibility()
    }

    func ephemeralKeyboard(_ keyboard: EphemeralKeyboardViewController, didSelectMessageTimeout timeout: TimeInterval) {
        inputBar.setInputBarState(.writing(ephemeral: timeout != 0 ? .message : .none), animated: true)
        updateMarkdownButton()

        ZMUserSession.shared()?.enqueueChanges {
            self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: timeout))
            self.updateRightAccessoryView()
        }
    }
    
}

extension ConversationInputBarViewController {
    var ephemeralState: EphemeralState {
        var state = EphemeralState.none
        if !sendButtonState.ephemeral {
            state = .none
        } else if self.conversation.hasSyncedMessageDestructionTimeout {
            state = .conversation
        } else {
            state = .message
        }
        
        return state
    }

    @objc func updateInputBar() {
        inputBar.changeEphemeralState(to: ephemeralState)
    }
}
