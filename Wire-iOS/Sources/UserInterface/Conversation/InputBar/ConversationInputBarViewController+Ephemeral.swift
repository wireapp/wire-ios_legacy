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

extension UIPopoverPresentationController {
    /// TODO: sandclock icon: <IconButton: 0x7f9d8e4c0940; baseClass = UIButton; frame = (0 12; 32 32); hidden = YES; opaque = NO; layer = <CALayer: 0x600000429040>>

//    (672.0, 860.0, 32.0, 32.0)
//    ▿ origin : (672.0, 860.0)
//    - x : 672.0
//    - y : 860.0
//    ▿ size : (32.0, 32.0)
//    - width : 32.0
//    - height : 32.0

    // timed icon:

//    <IconButton: 0x7f9d8e4c0940; baseClass = UIButton; frame = (32 12; 32 32); opaque = NO; layer = <CALayer: 0x600000429040>>

//    ▿ (704.0, 860.0, 32.0, 32.0)
//    ▿ origin : (704.0, 860.0)
//    - x : 704.0
//    - y : 860.0
//    ▿ size : (32.0, 32.0)
//    - width : 32.0
//    - height : 32.0
    func configIPadPopOver(from viewController: UIViewController, sourceView: UIView, presetInView: UIView, backgroundColor: UIColor) {
        self.sourceRect = sourceView.popoverSourceRect(from: viewController)
        self.sourceView = presetInView
        self.backgroundColor = backgroundColor
        permittedArrowDirections = .down
    }
}

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
        ephemeralKeyboardViewController?.preferredContentSize = CGSize(width: 320, height: 275) ///TODO: standard size?

        if let popover = ephemeralKeyboardViewController?.popoverPresentationController,
            let presetInView = self.parent?.view,
            let backgroundColor = ephemeralKeyboardViewController?.view.backgroundColor {
            popover.configIPadPopOver(from: self, sourceView: ephemeralIndicatorButton, presetInView: presetInView, backgroundColor: backgroundColor)
        }

        guard let controller = ephemeralKeyboardViewController else { return }
        self.parent?.present(controller, animated: true)
    }

    @objc public func updateEphemeralIndicatorButtonTitle(_ button: ButtonWithLargerHitArea) {
        guard let conversation = self.conversation,
              let timerValue = conversation.destructionTimeout else {
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
