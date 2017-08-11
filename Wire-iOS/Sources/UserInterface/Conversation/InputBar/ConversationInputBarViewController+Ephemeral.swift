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

    public func configureEphemeralKeyboardButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(ephemeralKeyboardButtonTapped), for: .touchUpInside)
    }

    public func ephemeralKeyboardButtonTapped(_ sender: IconButton) {
        updateEphemeralKeyboardVisibility()
    }

    fileprivate func updateEphemeralKeyboardVisibility() {

        let showPopover = traitCollection.horizontalSizeClass == .regular
        let noPopoverPresented = presentedViewController == nil
        let regularNotPresenting = showPopover && noPopoverPresented
        let compactNotPresenting = mode != .timeoutConfguration && !showPopover

        // presenting
        if compactNotPresenting || regularNotPresenting {
            trackEphemeralIfNeeded()
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
    
    fileprivate func trackEphemeralIfNeeded() {
        if (conversation.messageDestructionTimeout == 0) {
            Analytics.shared()?.tagMediaAction(.ephemeral, inConversation: conversation)
        }
    }

    private func presentEphemeralControllerAsPopover() {
        createEphemeralKeyboardViewController()
        ephemeralKeyboardViewController?.modalPresentationStyle = .popover
        let popover = ephemeralKeyboardViewController?.popoverPresentationController
        popover?.sourceRect = ephemeralIndicatorButton.frame
        popover?.sourceView = ephemeralIndicatorButton
        popover?.backgroundColor = ephemeralKeyboardViewController?.view.backgroundColor
        ephemeralKeyboardViewController?.preferredContentSize = CGSize(width: 320, height: 275)
        guard let controller = ephemeralKeyboardViewController else { return }
        present(controller, animated: true, completion: nil)
    }

    public func updateEphemeralIndicatorButtonTitle(_ button: ButtonWithLargerHitArea) {
        guard let conversation = self.conversation else {
            return
        }
        
        let title = conversation.destructionTimeout.shortDisplayString
        button.setTitle(title, for: .normal)
    }

}

extension ConversationInputBarViewController: EphemeralKeyboardViewControllerDelegate {

    func ephemeralKeyboardWantsToBeDismissed(_ keyboard: EphemeralKeyboardViewController) {
        updateEphemeralKeyboardVisibility()
    }

    func ephemeralKeyboard(_ keyboard: EphemeralKeyboardViewController, didSelectMessageTimeout timeout: ZMConversationMessageDestructionTimeout) {
        inputBar.setInputBarState(.writing(ephemeral: timeout != .none), animated: true)
        updateMarkdownButton()

        ZMUserSession.shared()?.enqueueChanges {
            self.conversation.updateMessageDestructionTimeout(timeout: timeout)
            self.updateRightAccessoryView()
            self.updateButtonIconsForEphemeral()
        }
    }

}
