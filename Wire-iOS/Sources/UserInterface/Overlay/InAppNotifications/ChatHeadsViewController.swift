//
//  ChatHeadsViewController.swift
//  Wire-iOS
//
//  Created by John Nguyen on 21.09.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography

public extension UIViewController {
    
    /// Determines if this view controller allows local in app notifications
    /// (chat heads) to appear. The default is true.
    ///
    @objc(shouldDisplayNotificationForMessage:isActiveAccount:)
    public func shouldDisplayNotification(for message: ZMConversationMessage, isActiveAccount: Bool) -> Bool {
        return true
    }
}

class ChatHeadsViewController: UIViewController {

    enum ChatHeadPresentationState {
        case `default`, hidden, showing, visible, dragging, hiding, last
    }
    
    fileprivate var chatHeadView: ChatHeadView?
    fileprivate var chatHeadViewLeftMarginConstraint: NSLayoutConstraint?
    fileprivate var chatHeadViewRightMarginConstraint: NSLayoutConstraint?
    private var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var chatHeadState: ChatHeadPresentationState = .hidden
    
    fileprivate let magicFloat: (String) -> CGFloat = {
        return WAZUIMagic.cgFloat(forIdentifier: "notifications.\($0)")
    }
    
    override func loadView() {
        view = PassthroughTouchesView()
        view.backgroundColor = .clear
    }
    
    // MARK: - Public Interface
    
    public func tryToDisplayNotification(_ note: UILocalNotification) {

        let isSelfAccount: (Account) -> Bool = { return $0.userIdentifier == note.zm_selfUserUUID }
        
        guard
            let accountManager = SessionManager.shared?.accountManager,
            let account = accountManager.accounts.first(where: isSelfAccount),
            let session = SessionManager.shared?.backgroundUserSessions[account.userIdentifier],
            let conversation = note.conversation(in: session.managedObjectContext),
            let message = note.message(in: conversation, in: session.managedObjectContext)
            else {
                return
        }
        
        guard shouldDisplay(message: message, isActiveAccount: accountManager.selectedAccount == account) else {
            return
        }
        
        if chatHeadState != .hidden {
            // hide visible chat head and try again
            hideChatHeadFromCurrentStateWithTiming(RBBEasingFunctionEaseInExpo, duration: 0.3)
            perform(#selector(tryToDisplayNotification(_:)), with: note, afterDelay: 0.3)
            return
        }
 
        chatHeadView = ChatHeadView(message: message, account: account)
        
        // FIXME: doesn't consider multi account yet
        chatHeadView!.onSelect = { _ in
            ZClientViewController.shared().select(conversation, focusOnView: true, animated: true)
            self.chatHeadView?.removeFromSuperview()
        }
        
        chatHeadState = .showing
        view.addSubview(chatHeadView!)
        
        // position offscreen left
        constrain(view, chatHeadView!) { view, chatHeadView in
            chatHeadView.top == view.top + 64 + magicFloat("container_inset_top")
            chatHeadViewLeftMarginConstraint = (chatHeadView.leading == view.leading - magicFloat("animation_container_inset"))
            chatHeadViewRightMarginConstraint = (chatHeadView.trailing <= view.trailing - magicFloat("animation_container_inset"))
        }
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanChatHead(_:)))
        chatHeadView!.addGestureRecognizer(panGestureRecognizer)
        
        // timed hiding
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideChatHeadView), object: nil)
        perform(#selector(hideChatHeadView), with: nil, afterDelay: Double(magicFloat("dismiss_delay_duration")))
        
        chatHeadView!.alpha = 0
        revealChatHeadFromCurrentState()
    }
    
    // MARK: - Private Helpers
    
    private func shouldDisplay(message: ZMConversationMessage, isActiveAccount: Bool) -> Bool {
        
        let isIPAD = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)
        
        // conversation list is visible in landscape
        if isActiveAccount && isIPAD && isLandscape {
            return false;
        }
        
        let clientVC = ZClientViewController.shared()!

        // if current conversation contains message & is visible
        if clientVC.currentConversation === message.conversation && clientVC.isConversationViewVisible {
            return false
        }
        
        if AppDelegate.shared().notificationWindowController?.voiceChannelController.voiceChannelIsActive ?? false {
            return false;
        }

        return clientVC.splitViewController.shouldDisplayNotification(for: message, isActiveAccount: isActiveAccount)
    }
    
    fileprivate func revealChatHeadFromCurrentState() {
        
        view.layoutIfNeeded()
        
        // slide in chat head from screen left
        UIView.wr_animate(
            easing: RBBEasingFunctionEaseOutExpo,
            duration: 0.35,
            animations: {
                self.chatHeadView?.alpha = 1
                self.chatHeadViewLeftMarginConstraint?.constant = self.magicFloat("container_inset_left")
                self.chatHeadViewRightMarginConstraint?.constant = -(self.magicFloat("container_inset_right"))
                self.view.layoutIfNeeded()
        },
            completion: { _ in self.chatHeadState = .visible }
        )
    }
    
    private func hideChatHeadFromCurrentState() {
        hideChatHeadFromCurrentStateWithTiming(RBBEasingFunctionEaseInExpo, duration: 0.35)
    }
    
    private func hideChatHeadFromCurrentStateWithTiming(_ timing: RBBEasingFunction, duration: TimeInterval) {
        chatHeadViewLeftMarginConstraint?.constant = -(magicFloat("animation_container_inset"))
        chatHeadViewRightMarginConstraint?.constant = -(magicFloat("animation_container_inset"))
        chatHeadState = .hiding
        
        UIView.wr_animate(
            easing: RBBEasingFunctionEaseOutExpo,
            duration: duration,
            animations: {
                self.chatHeadView?.alpha = 0
                self.view.layoutIfNeeded()
        },
            completion: { _ in
                self.chatHeadView?.removeFromSuperview()
                self.chatHeadState = .hidden
        })
    }
    
    @objc private func hideChatHeadView() {
        
        if chatHeadState == .dragging {
            perform(#selector(hideChatHeadView), with: nil, afterDelay: Double(magicFloat("dismiss_delay_duration")))
            return
        }
        
        hideChatHeadFromCurrentState()
    }
}


// MARK: - Interaction

extension ChatHeadsViewController {
    
    @objc fileprivate func onPanChatHead(_ pan: UIPanGestureRecognizer) {
        
        let offset = pan.translation(in: view)
        
        switch pan.state {
        case .began:
            chatHeadState = .dragging
        
        case .changed:
            // if pan left, move chathead with finger, else apply pan resistance
            let viewOffsetX = offset.x < 0 ? offset.x : (1.0 - (1.0/((offset.x * 0.15 / view.bounds.width) + 1.0))) * view.bounds.width
            chatHeadViewLeftMarginConstraint?.constant = viewOffsetX + magicFloat("container_inset_left")
            chatHeadViewRightMarginConstraint?.constant = viewOffsetX - magicFloat("container_inset_right")
            
        case .ended, .failed, .cancelled:
            guard offset.x < 0 && fabs(offset.x) > magicFloat("gesture_threshold") else {
                revealChatHeadFromCurrentState()
                break
            }

            chatHeadViewLeftMarginConstraint?.constant = -view.bounds.width
            chatHeadViewRightMarginConstraint?.constant = -view.bounds.width
            
            chatHeadState = .hiding
            
            // calculate time from formula dx = t * v + d0
            let velocityVector = pan.velocity(in: view)
            var time = Double((view.bounds.width - fabs(offset.x)) / fabs(velocityVector.x))
            
            // min/max animation duration
            if time < 0.05 { time = 0.05 }
            else if time > 0.2 { time = 0.2 }
            
            UIView.wr_animate(easing: RBBEasingFunctionEaseInQuad, duration: time, animations: view.layoutIfNeeded) { _ in
                self.chatHeadView?.removeFromSuperview()
                self.chatHeadState = .hidden
            }
            
        default:
            break
        }
    }
}
