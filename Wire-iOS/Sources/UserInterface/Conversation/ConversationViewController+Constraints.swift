//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ConversationViewController {
    func updateOutgoingConnectionVisibility() {

        let outgoingConnection: Bool = conversation.relatedConnectionState == .sent
        contentViewController.tableView.isScrollEnabled = !outgoingConnection

        if outgoingConnection {
            if outgoingConnectionViewController != nil {
                return
            }

            createOutgoingConnectionViewController()

            if let outgoingConnectionViewController = outgoingConnectionViewController {
                outgoingConnectionViewController.willMove(toParent: self)
                view.addSubview(outgoingConnectionViewController.view)
                addChild(outgoingConnectionViewController)
                NSLayoutConstraint.activate([
                    outgoingConnectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    outgoingConnectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    outgoingConnectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        } else {
            outgoingConnectionViewController?.willMove(toParent: nil)
            outgoingConnectionViewController?.view.removeFromSuperview()
            outgoingConnectionViewController?.removeFromParent()
            self.outgoingConnectionViewController = nil
        }
    }

    func createConstraints() {
        [conversationBarController.view,
         contentViewController.view,
         inputBarController.view].forEach {$0?.translatesAutoresizingMaskIntoConstraints = false}

        NSLayoutConstraint.activate([
            conversationBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversationBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversationBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        contentViewController.view.bottomAnchor.constraint(equalTo: inputBarController.view.topAnchor).isActive = true
        NSLayoutConstraint.activate([
            inputBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        inputBarBottomMargin = inputBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        inputBarBottomMargin?.isActive = true

        inputBarZeroHeight = inputBarController.view.heightAnchor.constraint(equalToConstant: 0)
    }

    @objc
    func keyboardFrameWillChange(_ notification: Notification) {
        // We only respond to keyboard will change frame if the first responder is not the input bar
        if invisibleInputAccessoryView.window == nil {
            UIView.animate(withKeyboardNotification: notification, in: view, animations: { [weak self] keyboardFrameInView in
                guard let weakSelf = self else { return }

                weakSelf.inputBarBottomMargin?.constant = -keyboardFrameInView.size.height
            })
        } else {
            if let screenRect: CGRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                let currentFirstResponder = UIResponder.currentFirst,
            let height = currentFirstResponder.inputAccessoryView?.bounds.size.height {

                let keyboardSize = CGSize(width: screenRect.size.width, height: height)
                UIView.setLastKeyboardSize(keyboardSize)
            }
        }
    }

}
