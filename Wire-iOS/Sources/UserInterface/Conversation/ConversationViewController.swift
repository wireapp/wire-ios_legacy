//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
    func createContentViewController() {
        contentViewController = ConversationContentViewController(conversation: conversation,
                                                                  message: visibleMessage,
                                                                  mediaPlaybackManager: zClientViewController?.mediaPlaybackManager,
                                                                  session: session)
        contentViewController.delegate = self
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.bottomMargin = 16
        inputBarController.mentionsView = contentViewController.mentionsSearchResultsViewController
        contentViewController.mentionsSearchResultsViewController.delegate = inputBarController
    }
    
    @objc
    func createMediaBarViewController() {
        mediaBarViewController = MediaBarViewController(mediaPlaybackManager: ZClientViewController.shared?.mediaPlaybackManager)
        mediaBarViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMediaBar(_:))))
    }

    @objc
    func didTapMediaBar(_ tapGestureRecognizer: UITapGestureRecognizer?) {
        if let mediaPlayingMessage = AppDelegate.shared().mediaPlaybackManager?.activeMediaPlayer?.sourceMessage,
            conversation == mediaPlayingMessage.conversation {
            contentViewController.scroll(to: mediaPlayingMessage, completion: nil)
        }
    }
}

//@interface ConversationViewController (Content) <ConversationContentViewControllerDelegate>
//@end

extension ConversationViewController: ConversationContentViewControllerDelegate {
    func didTap(onUserAvatar user: UserType?, view: UIView?, frame: CGRect) {
        tap(onUser: user, view: view, frame: frame)
    }
    
    func conversationContentViewController(_ contentViewController: ConversationContentViewController?, willDisplayActiveMediaPlayerFor message: ZMConversationMessage?) {
        conversationBarController.dismissBar(mediaBarViewController)
    }
    
    func conversationContentViewController(_ contentViewController: ConversationContentViewController?, didEndDisplayingActiveMediaPlayerFor message: ZMConversationMessage?) {
        conversationBarController.presentBar(mediaBarViewController)
    }
    
    func conversationContentViewController(_ contentViewController: ConversationContentViewController?, didTriggerResending message: ZMConversationMessage?) {
        ZMUserSession.shared().enqueueChanges({
            message?.resend()
        })
    }
    
    func conversationContentViewController(_ contentViewController: ConversationContentViewController?, didTriggerEditing message: ZMConversationMessage?) {
        let text = message?.textMessageData.messageText
        
        if nil != text {
            inputBarController.edit(message)
        }
    }
    
    func conversationContentViewController(_ contentViewController: ConversationContentViewController?, didTriggerReplyingTo message: ZMConversationMessage?) {
        let replyComposingView = contentViewController?.createReplyComposingView(for: message)
        inputBarController.reply(to: message, composingView: replyComposingView)
    }
    
    func conversationContentViewController(_ controller: ConversationContentViewController?, shouldBecomeFirstResponderWhenShowMenuFromCell cell: UIView?) -> Bool {
        if inputBarController.inputBar.textView.isFirstResponder {
            inputBarController.inputBar.textView.overrideNextResponder = cell
            
            NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide(_:)), name: UIMenuController.didHideMenuNotification, object: nil)
            
            return false
        } else {
            return true
        }
    }
    
    func conversationContentViewController(_ contentViewController: ConversationContentViewController?, performImageSaveAnimation snapshotView: UIView?, sourceRect: CGRect) {
        if let snapshotView = snapshotView {
            view.addSubview(snapshotView)
        }
        snapshotView?.frame = view.convert(sourceRect, from: contentViewController?.view)
        
        let targetView = inputBarController.photoButton
        let targetCenter = view.convert(targetView?.center ?? CGPoint.zero, from: targetView?.superview)
        
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseIn, animations: {
            snapshotView?.center = targetCenter
            snapshotView?.alpha = 0
            snapshotView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }) { finished in
            snapshotView?.removeFromSuperview()
            self.inputBarController.bounceCameraIcon()
        }
    }
    
    func conversationContentViewControllerWants(toDismiss controller: ConversationContentViewController?) {
        openConversationList()
    }
    
    func conversationContentViewController(_ controller: ConversationContentViewController?, presentGuestOptionsFrom sourceView: UIView?) {
        if conversation.conversationType != ZMConversationTypeGroup {
            ZMLogError("Illegal Operation: Trying to show guest options for non-group conversation")
            return
        }
        let groupDetailsViewController = GroupDetailsViewController(conversation: conversation)
        let navigationController = groupDetailsViewController.wrapInNavigationController
        groupDetailsViewController.presentGuestOptions(animated: false)
        presentParticipantsViewController(navigationController, from: sourceView)
    }
    
    func conversationContentViewController(_ controller: ConversationContentViewController?, presentParticipantsDetailsWithSelectedUsers selectedUsers: [ZMUser]?, from sourceView: UIView?) {
        let participantsController = self.participantsController
        if (participantsController is UINavigationController) {
            let navigationController = participantsController as? UINavigationController
            if (navigationController?.topViewController is GroupDetailsViewController) {
                (navigationController?.topViewController as? GroupDetailsViewController)?.presentParticipantsDetails(withUsers: conversation.sortedOtherParticipants, selectedUsers: selectedUsers, animated: false)
            }
        }
        presentParticipantsViewController(participantsController, from: sourceView)
    }
}
