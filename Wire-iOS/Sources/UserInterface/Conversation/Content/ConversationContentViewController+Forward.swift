//
//  ConversationContentViewController+Forward.swift
//  Wire-iOS
//
//  Created by Mihail Gerasimenko on 11/8/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

extension ZMConversation: ConversationTypeProtocol {
}

extension ZMUser: AccentColorProvider {
}

extension ConversationContentViewController {
    @objc public func showForwardFor(message: ZMConversationMessage) {
        let conversations = SessionObjectCache.shared().allConversations.map { $0 as! ZMConversation }
        let shareViewController = ShareViewController(conversations: conversations)
        shareViewController.accentColorProvider = ZMUser.selfUser(inUserSession: ZMUserSession.shared())
        shareViewController.delegate = self
        self.parent?.present(shareViewController, animated: true, completion: .none)
    }
}

extension ConversationContentViewController: ShareViewControllerDelegate {
    public func shareViewControllerDidSelect<I>(shareController: ShareViewController<I>, conversations: [I]) {
        
    }
    
    public func shareViewControllerWantsToBeDismissed<I>(shareController: ShareViewController<I>) {
        self.parent?.dismiss()
    }
}
