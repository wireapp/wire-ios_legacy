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
    
    func barButtonItem(withType type: ZetaIconType, target: AnyObject?, action: Selector, accessibilityIdentifier: String?, imageEdgeInsets: UIEdgeInsets = .zero) -> UIBarButtonItem {
        let button = IconButton.iconButtonDefault()
        button.setIcon(type, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.imageEdgeInsets = imageEdgeInsets
        return UIBarButtonItem(customView: button)
    }
    
    var audioCallBarButtonItem: UIBarButtonItem {
        let button = barButtonItem(withType: .callAudio,
                                   target: self,
                                   action: #selector(ConversationViewController.voiceCallItemTapped(_:)),
                                   accessibilityIdentifier: "audioCallBarButton",
                                   imageEdgeInsets: UIEdgeInsetsMake(0, 0, 0, -16))
        return button
    }
    
    var videoCallBarButtonItem: UIBarButtonItem {
        let button = barButtonItem(withType: .callVideo,
                                   target: self,
                                   action: #selector(ConversationViewController.videoCallItemTapped(_:)),
                                   accessibilityIdentifier: "videoCallBarButton",
                                   imageEdgeInsets: UIEdgeInsetsMake(0, 0, 0, -16))
        return button
    }
    
    var backBarButtonItem: UIBarButtonItem {
        let leftButtonIcon: ZetaIconType = (self.parent?.wr_splitViewController?.layoutSize == .compact) ? .backArrow : .hamburger
        
        return barButtonItem(withType: leftButtonIcon,
                             target: self,
                             action: #selector(ConversationViewController.onBackButtonPressed(_:)),
                             accessibilityIdentifier: "ConversationBackButton",
                             imageEdgeInsets: UIEdgeInsetsMake(0, -16, 0, 0))
    }
    
    var collectionsBarButtonItem: UIBarButtonItem {
        return barButtonItem(withType: .library,
                             target: self,
                             action: #selector(ConversationViewController.onCollectionButtonPressed(_:)),
                             accessibilityIdentifier: "collection",
                             imageEdgeInsets: UIEdgeInsetsMake(0, -16, 0, 0))
    }
    
    public func rightNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly else { return [] }
        if conversation.conversationType == .oneOnOne {
            return [audioCallBarButtonItem, videoCallBarButtonItem]
        }

        return [audioCallBarButtonItem]
    }
    
    public func leftNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []
        
        if self.parent?.wr_splitViewController?.layoutSize != .regularLandscape {
            items.append(backBarButtonItem)
        }
        
        items.append(collectionsBarButtonItem)
        
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
        
        let navigationController = collections.wrap(inNavigationControllerClass: RotationAwareNavigationController.self)
        navigationController.transitioningDelegate = self.conversationDetailsTransitioningDelegate

        self.parent?.present(navigationController, animated: true, completion: {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        })
        
        collections.onDismiss = {[weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.parent?.dismiss(animated: true, completion: { 
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            })
        }
    }
}

extension ConversationViewController: CollectionsViewControllerDelegate {
    public func collectionsViewController(_ viewController: CollectionsViewController, performAction action: MessageAction, onMessage message: ZMConversationMessage) {
        switch action {
        case .forward:
            self.parent?.dismiss(animated: true) {
                self.contentViewController.scroll(to: message) {[weak self] cell in
                    guard let `self` = self else {
                        return
                    }
                    self.contentViewController.showForwardFor(message: message, fromCell: cell)
                }
            }
            
            
        case .showInConversation:
            self.parent?.dismiss(animated: true) { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.contentViewController.scroll(to: message)
            }
        default:
            break
        }
    }
}
