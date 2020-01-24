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
import WireDataModel

extension ConversationViewController {
    @objc
    func addParticipants(_ participants: Set<ZMUser>) {
        var newConversation: ZMConversation? = nil
        
        ZMUserSession.shared()?.enqueueChanges({
            newConversation = self.conversation.addParticipantsOrCreateConversation(participants)
        }, completionHandler: { [weak self] in
            if let newConversation = newConversation {
                self?.zClientViewController?.select(conversation: newConversation, focusOnView: true, animated: true)
            }
        })
    }
    
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
        if let mediaPlayingMessage = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage,
            conversation == mediaPlayingMessage.conversation {
            contentViewController.scroll(to: mediaPlayingMessage, completion: nil)
        }
    }
    
    @objc
    func createInputBarController() {
        inputBarController = ConversationInputBarViewController(conversation: conversation)
        inputBarController.delegate = self
        inputBarController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Create an invisible input accessory view that will allow us to take advantage of built in keyboard
        // dragging and sizing of the scrollview
        invisibleInputAccessoryView = InvisibleInputAccessoryView()
        invisibleInputAccessoryView.delegate = self
        invisibleInputAccessoryView.isUserInteractionEnabled = false // make it not block touch events
        invisibleInputAccessoryView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        if !AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal {
            inputBarController.inputBar.invisibleInputAccessoryView = invisibleInputAccessoryView
        }
    }
    
    @objc
    func updateInputBarVisibility() {
        if conversation.isReadOnly {
            inputBarController.inputBar.textView.resignFirstResponder()
            inputBarController.dismissMentionsIfNeeded()
            inputBarController.removeReplyComposingView()
        }
        
        inputBarZeroHeight?.isActive = conversation.isReadOnly
        view.setNeedsLayout()
    }
    
    @objc
    func setupNavigatiomItem() {
        titleView = ConversationTitleView(conversation: conversation, interactive: true)
        
        titleView.tapHandler = { [weak self] button in
            if let superview = self?.titleView.superview,
                let participantsController = self?.participantsController {
                self?.presentParticipantsViewController(participantsController, from: superview)
            }
        }
        titleView.configure()
        
        navigationItem.titleView = titleView
        navigationItem.leftItemsSupplementBackButton = false
        
        updateRightNavigationItemsButtons()
    }
}

//MARK: - InvisibleInputAccessoryViewDelegate

extension ConversationViewController: InvisibleInputAccessoryViewDelegate {
    
    // WARNING: DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING
    func invisibleInputAccessoryView(_ invisibleInputAccessoryView: InvisibleInputAccessoryView, superviewFrameChanged frame: CGRect?) {
        // Adjust the input bar distance from bottom based on the invisibleAccessoryView
        var distanceFromBottom: CGFloat = 0
        
        // On iOS 8, the frame goes to zero when the accessory view is hidden
        if frame?.equalTo(.zero) == false {
            
            let convertedFrame = view.convert(invisibleInputAccessoryView.superview?.frame ?? .zero, from: invisibleInputAccessoryView.superview?.superview)
            
            // We have to use intrinsicContentSize here because the frame may not have actually been updated yet
            let newViewHeight = invisibleInputAccessoryView.intrinsicContentSize.height
            
            distanceFromBottom = view.frame.size.height - convertedFrame.origin.y - newViewHeight
            
            distanceFromBottom = max(0, distanceFromBottom)
        }
        
        let closure: () -> () = {
            self.inputBarBottomMargin?.constant = -distanceFromBottom
            self.view.layoutIfNeeded()
        }
        
        if isAppearing {
            UIView.performWithoutAnimation(closure)
        } else {
            closure()
        }        
    }
}

//MARK: - ZMConversationObserver

extension ConversationViewController: ZMConversationObserver {
    public func conversationDidChange(_ note: ConversationChangeInfo) {
        if note.causedByConversationPrivacyChange {
            presentPrivacyWarningAlert(for: note)
        }
        
        if note.participantsChanged ||
           note.connectionStateChanged {
            updateRightNavigationItemsButtons()
            updateLeftNavigationBarItems()
            updateOutgoingConnectionVisibility()
            contentViewController.updateTableViewHeaderView()
            updateInputBarVisibility()
        }
        
        if note.participantsChanged ||
           note.externalParticipantsStateChanged {
            updateGuestsBarVisibility()
        }
        
        if note.nameChanged ||
           note.securityLevelChanged ||
           note.connectionStateChanged ||
           note.legalHoldStatusChanged {
            setupNavigatiomItem()
        }
    }
    
    func dismissProfileClientViewController(_ sender: UIBarButtonItem?) {
        dismiss(animated: true)
    }
}

//MARK: - ZMConversationListObserver

extension ConversationViewController: ZMConversationListObserver {
    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateLeftNavigationBarItems()
    }
    
    public func conversation(inside list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        updateLeftNavigationBarItems()
    }
}

//MARK: - InputBar

extension ConversationViewController: ConversationInputBarViewControllerDelegate {
    func conversationInputBarViewControllerDidComposeText(text: String,
                                                          mentions: [Mention],
                                                          replyingTo message: ZMConversationMessage?) {
        contentViewController.scrollToBottom()
        inputBarController.sendController.sendTextMessage(text, mentions: mentions, replyingTo: message)
    }
    
    func conversationInputBarViewControllerShouldBeginEditing(_ controller: ConversationInputBarViewController) -> Bool {
        if !contentViewController.isScrolledToBottom && !controller.isEditingMessage &&
            !controller.isReplyingToMessage {
            collectionController = nil
            contentViewController.searchQueries = []
            contentViewController.scrollToBottom()
        }
        
        setGuestBarForceHidden(true)
        return true
    }
    
    func conversationInputBarViewControllerShouldEndEditing(_ controller: ConversationInputBarViewController) -> Bool {
        setGuestBarForceHidden(false)
        return true
    }
    
    func conversationInputBarViewControllerDidFinishEditing(_ message: ZMConversationMessage,
                                                            withText newText: String?,
                                                            mentions: [Mention]) {
        contentViewController.didFinishEditing(message)
        ZMUserSession.shared()?.enqueueChanges({
            if let newText = newText,
                !newText.isEmpty {
                let fetchLinkPreview = !Settings.shared().disableLinkPreviews
                message.textMessageData?.editText(newText, mentions: mentions, fetchLinkPreview: fetchLinkPreview)
            } else {
                ZMMessage.deleteForEveryone(message)
            }
        })
    }
    
    func conversationInputBarViewControllerDidCancelEditing(_ message: ZMConversationMessage) {
        contentViewController.didFinishEditing(message)
    }
    
    func conversationInputBarViewControllerWants(toShow message: ZMConversationMessage) {
        contentViewController.scroll(to: message) { cell in
            self.contentViewController.highlight(message)
        }
    }
    
    func conversationInputBarViewControllerEditLastMessage() {
        contentViewController.editLastMessage()
    }
    
}
