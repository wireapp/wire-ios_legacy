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

extension ConversationViewController {
    @objc
    func updateOutgoingConnectionVisibility() {
        guard let conversation = conversation else {
            return
        }

        let outgoingConnection: Bool = conversation.relatedConnectionState == .sent
        contentViewController.tableView.isScrollEnabled = !outgoingConnection


        guard let outgoingConnectionViewController = outgoingConnectionViewController else {
            return
        }

        if outgoingConnection {
            createOutgoingConnectionViewController()

            addToSelf(outgoingConnectionViewController)

            outgoingConnectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
            outgoingConnectionViewController.view.fitInSuperview(exclude: [.top])
        } else {
            outgoingConnectionViewController.willMove(toParent: nil)
            outgoingConnectionViewController.view.removeFromSuperview()
            outgoingConnectionViewController.removeFromParent()
            self.outgoingConnectionViewController = nil
        }
    }

    @objc
    func createConstraints() {
        [conversationBarController.view,
         contentViewController.view,
         inputBarController.view].forEach(){$0?.translatesAutoresizingMaskIntoConstraints = false}

        conversationBarController.view.fitInSuperview(exclude: [.bottom])
        contentViewController.view.fitInSuperview(exclude: [.bottom])

        contentViewController.view.bottomAnchor.constraint(equalTo: inputBarController.view.topAnchor).isActive = true
        let constraints = inputBarController.view.fitInSuperview(exclude:[.top])

        inputBarBottomMargin = constraints[.bottom]

        inputBarZeroHeight = inputBarController.view.heightAnchor.constraint(equalToConstant: 0)
    }
}
