
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

fileprivate typealias ConversationCreatedBlock = (ZMConversation?) -> Void

extension ConversationListViewController.ViewModel: StartUIDelegate {
    func startUI(_ startUI: StartUIViewController, didSelect users: Set<ZMUser>) {
        guard users.count > 0 else {
            return
        }
        
        withConversationForUsers(users, callback: { conversation in
            guard let conversation = conversation else { return }
            
            ZClientViewController.shared()?.select(conversation, focusOnView: true, animated: true)
        })
    }
    
    func startUI(_ startUI: StartUIViewController, createConversationWith users: Set<ZMUser>, name: String, allowGuests: Bool, enableReceipts: Bool) {
        let createConversationClosure = {
            self.createConversation(withUsers: users, name: name, allowGuests: allowGuests, enableReceipts: enableReceipts)
        }
        (viewController as? UIViewController)?.dismissIfNeeded(completion: createConversationClosure)
    }

    func startUI(_ startUI: StartUIViewController, didSelect conversation: ZMConversation) {
        ZClientViewController.shared()?.select(conversation, focusOnView: true, animated: true)
    }
    
    private func withConversationForUsers(_ users: Set<ZMUser>?, callback onConversationCreated: @escaping ConversationCreatedBlock) {
        
        guard let users = users,
            let userSession = ZMUserSession.shared() else { return }
        
        viewController?.setState(.conversationList, animated:true) {
            if users.count == 1,
                let user = users.first {
                var oneToOneConversation: ZMConversation? = nil
                userSession.enqueueChanges({
                    oneToOneConversation = user.oneToOneConversation
                }, completionHandler: {
                    delay(0.3) {
                        onConversationCreated(oneToOneConversation)
                    }
                })
            } else if users.count > 1 {
                var conversation: ZMConversation? = nil
                
                userSession.enqueueChanges({
                    let team = ZMUser.selfUser().team
                    
                    conversation = ZMConversation.insertGroupConversation(intoUserSession: userSession, withParticipants: Array(users), in: team)
                }, completionHandler: {
                    delay(0.3) {
                        onConversationCreated(conversation)
                    }
                })
            }
        }
    }
    
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
