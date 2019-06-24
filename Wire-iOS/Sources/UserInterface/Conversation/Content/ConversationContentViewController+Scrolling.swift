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

extension ConversationContentViewController {
    
    @objc(scrollToMessage:completion:)
    public func scroll(to message: ZMConversationMessage?, completion: ((UIView)->())? = .none) {
        if let message = message {

            if message.hasBeenDeleted {
                presentAlertWithOKButton(message: "conversation.alert.message_deleted".localized)
            } else {
                dataSource.loadMessages(near: message) { index in

                    guard message.conversation == self.conversation else {
                        fatal("Message from the wrong conversation")
                    }

                    guard let indexToShow = index else {
                        return
                    }

                    self.tableView.scrollToRow(at: indexToShow, at: .top, animated: false)

                    if let cell = self.tableView.cellForRow(at: indexToShow) {
                        completion?(cell)
                    }
                }
            }
        } else {
            dataSource.loadMessages()
        }
        
        updateTableViewHeaderView()
    }
    
    @objc public func scrollToBottom() {
        guard !isScrolledToBottom else { return }
        
        dataSource.loadMessages()
        tableView.scroll(toIndex: 0)
        
        updateTableViewHeaderView()
    }
}
