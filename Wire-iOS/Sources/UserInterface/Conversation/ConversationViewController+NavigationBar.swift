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
import WireSyncEngine
import WireCommonComponents

// MARK: - Update left navigator bar item when size class changes
extension ConversationViewController {

    func addCallStateObserver() -> Any? {
        return conversation.voiceChannel?.addCallStateObserver(self)
    }

    var audioCallButton: UIBarButtonItem {
        let button = UIBarButtonItem(icon: .phone, target: self, action: #selector(ConversationViewController.voiceCallItemTapped(_:)))
        button.accessibilityIdentifier = "audioCallBarButton"
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = "call.actions.label.make_audio_call".localized
        return button
    }

    var videoCallButton: UIBarButtonItem {
        let button = UIBarButtonItem(icon: .videoCall, target: self, action: #selector(ConversationViewController.videoCallItemTapped(_:)))
        button.accessibilityIdentifier = "videoCallBarButton"
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = "call.actions.label.make_video_call".localized
        return button
    }

    var joinCallButton: UIBarButtonItem {
        let button = IconButton()
        button.adjustsTitleWhenHighlighted = true
        button.adjustBackgroundImageWhenHighlighted = true
        button.setTitle("conversation_list.right_accessory.join_button.title".localized(uppercased: true), for: .normal)
        button.accessibilityLabel = "conversation.join_call.voiceover".localized
        button.accessibilityTraits.insert(.startsMediaSession)
        button.titleLabel?.font = FontSpec(.small, .semibold).font
        button.backgroundColor = .strongLimeGreen
        button.addTarget(self, action: #selector(joinCallButtonTapped), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 24))
        button.layer.cornerRadius = button.bounds.height / 2
        return UIBarButtonItem(customView: button)
    }

    var backButton: UIBarButtonItem {
        let hasUnreadInOtherConversations = self.conversation.hasUnreadMessagesInOtherConversations
        let arrowIcon: StyleKitIcon = view.isRightToLeft
            ? (hasUnreadInOtherConversations ? .forwardArrowWithDot : .forwardArrow)
            : (hasUnreadInOtherConversations ? .backArrowWithDot : .backArrow)

        let icon: StyleKitIcon = (self.parent?.wr_splitViewController?.layoutSize == .compact) ? arrowIcon : .hamburger
        let action = #selector(ConversationViewController.onBackButtonPressed(_:))
        let button = UIBarButtonItem(icon: icon, target: self, action: action)
        button.accessibilityIdentifier = "ConversationBackButton"
        button.accessibilityLabel = "general.back".localized

        if hasUnreadInOtherConversations {
            button.tintColor = UIColor.accent()
            button.accessibilityValue = "conversation_list.voiceover.unread_messages.hint".localized
        }

        return button
    }

    var collectionsBarButtonItem: UIBarButtonItem {
        let showingSearchResults = (self.collectionController?.isShowingSearchResults ?? false)
        let action = #selector(ConversationViewController.onCollectionButtonPressed(_:))
        let button = UIBarButtonItem(icon: showingSearchResults ? .activeSearch : .search, target: self, action: action)
        button.accessibilityIdentifier = "collection"
        button.accessibilityLabel = "conversation.action.search".localized

        if showingSearchResults {
            button.tintColor = UIColor.accent()
        }

        return button
    }

    func rightNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly, conversation.localParticipants.count != 0 else { return [] }

        if conversation.canJoinCall {
            return [joinCallButton]
        } else if conversation.isCallOngoing {
            return []
        } else if conversation.canStartVideoCall {
            return [audioCallButton, videoCallButton]
        } else {
            return [audioCallButton]
        }
    }

    func leftNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []

        if self.parent?.wr_splitViewController?.layoutSize != .regularLandscape {
            items.append(backButton)
        }

        if self.shouldShowCollectionsButton() {
            items.append(collectionsBarButtonItem)
        }

        return items
    }

    func updateRightNavigationItemsButtons() {
        navigationItem.rightBarButtonItems = rightNavigationItems(forConversation: conversation)
    }

    /// Update left navigation bar items
    func updateLeftNavigationBarItems() {
        navigationItem.leftBarButtonItems = leftNavigationItems(forConversation: conversation)
    }

    private func shouldShowCollectionsButton() -> Bool {
        switch self.conversation.conversationType {
        case .group: return true
        case .oneOnOne:
            if let connection = conversation.connection,
                connection.status != .pending && connection.status != .sent {
                return true
            } else {
                return nil != conversation.teamRemoteIdentifier
            }
        default: return false
        }
    }

    @objc
    func voiceCallItemTapped(_ sender: UIBarButtonItem) {
        endEditing()
        startCallController.startAudioCall(started: ConversationInputBarViewController.endEditingMessage)
    }

    @objc func videoCallItemTapped(_ sender: UIBarButtonItem) {
        endEditing()
        startCallController.startVideoCall(started: ConversationInputBarViewController.endEditingMessage)
    }

    @objc private dynamic func joinCallButtonTapped(_sender: AnyObject!) {
        startCallController.joinCall()
    }

    @objc
    private func onCollectionButtonPressed(_ sender: AnyObject!) {
        if self.collectionController == .none {
            let collections = CollectionsViewController(conversation: conversation)
            collections.delegate = self

            collections.onDismiss = { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }

                weakSelf.collectionController?.dismiss(animated: true)
            }
            collectionController = collections
        } else {
            collectionController?.refetchCollection()
        }

        collectionController?.shouldTrackOnNextOpen = true

        let navigationController = KeyboardAvoidingViewController(viewController: self.collectionController!).wrapInNavigationController()

        ZClientViewController.shared?.present(navigationController, animated: true)
    }

    @objc func dismissCollectionIfNecessary() {
        if let collectionController = self.collectionController {
            collectionController.dismiss(animated: false)
        }
    }
}

extension ConversationViewController: CollectionsViewControllerDelegate {
    func collectionsViewController(_ viewController: CollectionsViewController, performAction action: MessageAction, onMessage message: ZMConversationMessage) {
        switch action {
        case .forward:
            viewController.dismissIfNeeded(animated: true) {
                self.contentViewController.scroll(to: message) { cell in
                    self.contentViewController.showForwardFor(message: message, from: cell)
                }
            }

        case .showInConversation:
            viewController.dismissIfNeeded(animated: true) {
                self.contentViewController.scroll(to: message) { _ in
                    self.contentViewController.highlight(message)
                }
            }

        case .reply:
            viewController.dismissIfNeeded(animated: true) {
                self.contentViewController.scroll(to: message) { cell in
                    self.contentViewController.perform(action: .reply, for: message, view: cell)
                }
            }

        default:
            contentViewController.perform(action: action, for: message, view: view)
        }
    }
}

extension ConversationViewController: WireCallCenterCallStateObserver {

    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateRightNavigationItemsButtons()
    }

}

extension ZMConversation {

    /// Whether there is an incoming or inactive incoming call that can be joined.
    var canJoinCall: Bool {
        return voiceChannel?.state.canJoinCall ?? false
    }

    var canStartVideoCall: Bool {
        guard !isCallOngoing else { return false }

        guard !(type(of: self).useConferenceCalling) else { return true }

        if self.conversationType == .oneOnOne {
            return true
        }

        if self.conversationType == .group &&
            ZMUser.selfUser().isTeamMember &&
            isConversationEligibleForVideoCalls {
            return true
        }

        return false
    }

    var isConversationEligibleForVideoCalls: Bool {
        return self.localParticipants.count <= ZMConversation.maxVideoCallParticipants
    }

    var isCallOngoing: Bool {
        return voiceChannel?.state.isCallOngoing ?? true
    }
}

extension CallState {

    var canJoinCall: Bool {
        switch self {
        case .incoming: return true
        default: return false
        }
    }

    var isCallOngoing: Bool {
        switch self {
        case .none, .incoming: return false
        default: return true
        }
    }
}
