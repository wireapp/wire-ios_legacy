//
//  ConversationContentViewController+Forward.swift
//  Wire-iOS
//
//  Created by Mihail Gerasimenko on 11/8/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import zmessaging

extension ZMConversation: ConversationTypeProtocol {
}

extension ZMUser: AccentColorProvider {
}

extension ZMMessage: ShareableMessageType {
    public typealias I = ZMConversation

    public func shareTo<ZMConversation>(conversations: [ZMConversation]) {
        
        if let imageMessageData = self.imageMessageData {
            ZMUserSession.shared().performChanges {
                conversations.forEach({ conversation in
                    let imageData = imageMessageData.imageData
//                    conversation.appendMessage(withImageData: imageData)
                })
            }
        }
    }
}

extension ConversationContentViewController {
    @objc public func showForwardFor(message: ZMConversationMessage) {
        let conversations = SessionObjectCache.shared().allConversations.map { $0 as! ZMConversation }
        let shareViewController = ShareViewController(shareable: message as! ZMMessage, conversations: conversations)
        
        if self.parent?.parent?.wr_splitViewController.layoutSize == .compact {
            shareViewController.modalPresentationStyle = .overCurrentContext
        }
        else {
            shareViewController.modalPresentationStyle = .formSheet
        }

        
        shareViewController.accentColorProvider = ZMUser.selfUser(inUserSession: ZMUserSession.shared())
        shareViewController.delegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(shareViewController, animated: true, completion: .none)
    }
}

extension ConversationContentViewController: ShareViewControllerDelegate {
    public func shareViewControllerDidShare<I, S>(shareController: ShareViewController<I, S>, conversations: [I]) {
        shareController.presentingViewController?.dismiss(animated: true, completion: .none)
    }

    public func shareViewControllerWantsToBeDismissed<I, S>(shareController: ShareViewController<I, S>) {
        shareController.presentingViewController?.dismiss(animated: true, completion: .none)
    }
}
