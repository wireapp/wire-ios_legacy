
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

extension ConversationListViewController.ViewModel: StartUIDelegate {
    func startUI(_ startUI: StartUIViewController!, didSelect users: Set<ZMUser>!) {
        guard users.count > 0 else {
            return
        }
        
        withConversationForUsers(users, callback: { conversation in
            if let conversation = conversation {
                ZClientViewController.shared()?.select(conversation, focusOnView: true, animated: true)
            }
        })
    }
    
    func startUI(_ startUI: StartUIViewController!, createConversationWith users: Set<ZMUser>?, name: String!, allowGuests: Bool, enableReceipts: Bool) {
        let createConversationClosure = {
            self.createConversation(withUsers: users, name: name, allowGuests: allowGuests, enableReceipts: enableReceipts)
        }
        (viewController as? UIViewController)?.dismissIfNeeded(completion: createConversationClosure)
    }

    func startUI(_ startUI: StartUIViewController!, didSelect conversation: ZMConversation!) {
        viewController?.dismissPeoplePicker(with: {
            ZClientViewController.shared()?.select(conversation, focusOnView: true, animated: true)
        })
    }
}

extension ConversationListViewController.ViewModel {
    private func createConversation(withUsers users: Set<ZMUser>?, name: String?, allowGuests: Bool, enableReceipts: Bool) {
        guard let users = users,
            let userSession = ZMUserSession.shared() else { return }

        var conversation: ZMConversation! = nil

        userSession.enqueueChanges({
            conversation = ZMConversation.insertGroupConversation(intoUserSession: userSession, withParticipants: Array(users), name: name, in: ZMUser.selfUser().team, allowGuests: allowGuests, readReceipts: enableReceipts)
        }, completionHandler:{
            delay(0.3) {
                ZClientViewController.shared()?.select(conversation, focusOnView: true, animated: true)
            }
        })
    }
}
