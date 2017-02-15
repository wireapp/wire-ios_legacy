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


import UIKit
import zmessaging
import Cartography

public extension ConversationViewController {
    
    func barButtonItem(withType type: ZetaIconType, target: AnyObject?, action: Selector, accessibilityIdentifier: String?, width: CGFloat = 30, imageEdgeInsets: UIEdgeInsets = .zero) -> IconButton {
        let button = IconButton.iconButtonDefault()
        button.setIcon(type, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: width, height: 20)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.imageEdgeInsets = imageEdgeInsets
        return button
    }
    
    var audioCallBarButtonItem: IconButton {
        let button = barButtonItem(withType: .callAudio,
                                   target: self,
                                   action: #selector(ConversationViewController.voiceCallItemTapped(_:)),
                                   accessibilityIdentifier: "audioCallBarButton",
                                   width: 38,
                                   imageEdgeInsets: UIEdgeInsetsMake(0, 0, 0, -16))
        return button
    }
    
    var videoCallBarButtonItem: IconButton {
        let button = barButtonItem(withType: .callVideo,
                                   target: self,
                                   action: #selector(ConversationViewController.videoCallItemTapped(_:)),
                                   accessibilityIdentifier: "videoCallBarButton",
                                   width: 30,
                                   imageEdgeInsets: UIEdgeInsetsMake(0, 0, 0, -8))
        return button
    }
    
    var backBarButtonItem: IconButton {
        let leftButtonIcon: ZetaIconType = (self.parent?.wr_splitViewController?.layoutSize == .compact) ? .backArrow : .hamburger
        
        return barButtonItem(withType: leftButtonIcon,
                             target: self,
                             action: #selector(ConversationViewController.onBackButtonPressed(_:)),
                             accessibilityIdentifier: "ConversationBackButton",
                             width: 38,
                             imageEdgeInsets: UIEdgeInsetsMake(0, -16, 0, 0))
    }
    
    var collectionsBarButtonItem: IconButton {
        return barButtonItem(withType: .search,
                             target: self,
                             action: #selector(ConversationViewController.onCollectionButtonPressed(_:)),
                             accessibilityIdentifier: "collection",
                             width: 30,
                             imageEdgeInsets: UIEdgeInsetsMake(0, -8, 0, 0))
    }
    
    public func rightNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly else { return [] }
        if conversation.conversationType == .oneOnOne {
            return [UIBarButtonItem(customView: audioCallBarButtonItem), UIBarButtonItem(customView: videoCallBarButtonItem)]
        }

        return [UIBarButtonItem(customView: audioCallBarButtonItem)]
    }
    
    private func shouldShowCollectionsButton() -> Bool {
        guard #available(iOS 8.3, *) else { return false }

        switch self.conversation.conversationType {
        case .group:
            return true
        case .oneOnOne:
            if let connection = conversation.connection,
                connection.status != .pending && connection.status != .sent {
                return true
            }
        default: return false
        }
        
        return false
    }
    
    public func leftNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []
        
        if self.parent?.wr_splitViewController?.layoutSize != .regularLandscape {
            let backButton = backBarButtonItem
            backButton.hitAreaPadding = CGSize(width: 28, height: 20)
            items.append(UIBarButtonItem(customView: backButton))
        }
        
        if self.shouldShowCollectionsButton() {
            let collectionsButton = collectionsBarButtonItem
            collectionsButton.hitAreaPadding = CGSize(width: 0, height: 20)
            items.append(UIBarButtonItem(customView: collectionsButton))
        }
        
        return items
    }
    
    private func confirmCallInGroup(completion: @escaping (_ accepted: Bool) -> ()) {
        let participantsCount = self.conversation.activeParticipants.count - 1
        let message = "conversation.call.many_participants_confirmation.message".localized(args: participantsCount)
        
        let confirmation = UIAlertController(title: "conversation.call.many_participants_confirmation.title".localized,
                                             message: message,
                                             preferredStyle: .alert)
        
        let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel) { _ in
            completion(false)
        }
        confirmation.addAction(actionCancel)
        
        let actionSend = UIAlertAction(title: "conversation.call.many_participants_confirmation.call".localized, style: .default) { _ in
            completion(true)
        }
        confirmation.addAction(actionSend)
        
        self.present(confirmation, animated: true, completion: .none)
    }
    
    func voiceCallItemTapped(_ sender: UIBarButtonItem) {
        let startCall = {
            ConversationInputBarViewController.endEditingMessage()
            self.conversation.startAudioCall(completionHandler: nil)
            Analytics.shared()?.tagMediaAction(.audioCall, inConversation: self.conversation)
        }
        
        if self.conversation.activeParticipants.count <= 4 {
            startCall()
        }
        else {
            self.confirmCallInGroup { accepted in
                if accepted {
                    startCall()
                }
            }
        }
    }
    
    func videoCallItemTapped(_ sender: UIBarButtonItem) {
        ConversationInputBarViewController.endEditingMessage()
        conversation.startVideoCall(completionHandler: nil)
        Analytics.shared()?.tagMediaAction(.videoCall, inConversation: conversation)
    }
    
    func onCollectionButtonPressed(_ sender: AnyObject!) {
        let collections = CollectionsViewController(conversation: conversation)
        collections.delegate = self
        
        self.collectionController = collections
        
        let navigationController = KeyboardAvoidingViewController(viewController: collections).wrapInNavigationController(RotationAwareNavigationController.self)
        navigationController.transitioningDelegate = self.conversationDetailsTransitioningDelegate

        ZClientViewController.shared().present(navigationController, animated: true, completion: {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        })
        
        collections.onDismiss = { [weak self] _ in
            guard let `self` = self, let collectionController = self.collectionController else {
                return
            }

            collectionController.dismiss(animated: true, completion: {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            })
        }
    }
    
    internal func dismissCollectionIfNecessary() {
        if let _ = self.collectionController {
            self.collectionController.dismiss(animated: false)
        }
    }
}

extension ConversationViewController: CollectionsViewControllerDelegate {
    public func collectionsViewController(_ viewController: CollectionsViewController, performAction action: MessageAction, onMessage message: ZMConversationMessage) {
        switch action {
        case .forward:
            viewController.dismiss(animated: true) {
                self.contentViewController.scroll(to: message) {[weak self] cell in
                    guard let `self` = self else {
                        return
                    }
                    self.contentViewController.showForwardFor(message: message, fromCell: cell)
                }
            }
            
            
        case .showInConversation:
            viewController.dismiss(animated: true) { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.contentViewController.scroll(to: message)
            }
        default:
            self.contentViewController.wants(toPerform: action, for: message)
            break
        }
    }
}
