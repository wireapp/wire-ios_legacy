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

    typealias IconColors = SemanticColors.Icon
    typealias ButtonColors = SemanticColors.Button
    typealias CallActions = L10n.Localizable.Call.Actions

    func addCallStateObserver() -> Any? {
        return conversation.voiceChannel?.addCallStateObserver(self)
    }

    var audioCallButton: UIButton {
        let button = IconButton()
        button.setIcon(.phone, size: .tiny, for: .normal)
        button.setIconColor(IconColors.foregroundDefault, for: .normal)

        button.accessibilityIdentifier = "audioCallBarButton"
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = CallActions.Label.makeAudioCall

        button.addTarget(self, action: #selector(ConversationViewController.voiceCallItemTapped(_:)), for: .touchUpInside)

        button.backgroundColor = ButtonColors.backgroundBarItem
        button.layer.borderWidth = 1
        button.setBorderColor(ButtonColors.borderBarItem, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        return button
    }

    var videoCallButton: UIButton {
        let button = IconButton()
        button.setIcon(.camera, size: .tiny, for: .normal)
        button.setIconColor(IconColors.foregroundDefault, for: .normal)

        button.accessibilityIdentifier = "videoCallBarButton"
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = CallActions.Label.makeVideoCall

        button.addTarget(self, action: #selector(ConversationViewController.videoCallItemTapped(_:)), for: .touchUpInside)

        button.backgroundColor = ButtonColors.backgroundBarItem
        button.layer.borderWidth = 1
        button.setBorderColor(ButtonColors.borderBarItem, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        return button
    }

    private var audioAndVideoCallButtons: UIView {
            let buttonStack = UIStackView(arrangedSubviews: [videoCallButton, audioCallButton])
            buttonStack.distribution = .fillEqually
            buttonStack.spacing = 0
            buttonStack.axis = .horizontal

            let buttonsView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 32))
            buttonsView.addSubview(buttonStack)

            buttonStack.translatesAutoresizingMaskIntoConstraints = false
            buttonStack.fitIn(view: buttonsView)

            return buttonsView
        }

    var joinCallButton: UIBarButtonItem {
        let button = IconButton(fontSpec: .smallSemiboldFont)
        button.adjustsTitleWhenHighlighted = true
        button.adjustBackgroundImageWhenHighlighted = true
        button.setTitle("conversation_list.right_accessory.join_button.title".localized(uppercased: true), for: .normal)
        button.accessibilityLabel = "conversation.join_call.voiceover".localized
        button.accessibilityTraits.insert(.startsMediaSession)
        button.backgroundColor = SemanticColors.LegacyColors.strongLimeGreen
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

    var shouldShowCollectionsButton: Bool {
        guard
            SecurityFlags.forceEncryptionAtRest.isEnabled == false,
            session.encryptMessagesAtRest == false
        else {
            return false
        }

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

    func rightNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly, conversation.localParticipants.count != 0 else { return [] }

        if conversation.canJoinCall {
            return [joinCallButton]
        } else if conversation.isCallOngoing {
            return []
        } else if conversation.canStartVideoCall {
            let barButtonItems = UIBarButtonItem(customView: audioAndVideoCallButtons)
            return [barButtonItems]
        } else {
            let barButtonItem = UIBarButtonItem(customView: audioCallButton)
            return [barButtonItem]
        }
    }

    func leftNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []

        if self.parent?.wr_splitViewController?.layoutSize != .regularLandscape {
            items.append(backButton)
        }

        if shouldShowCollectionsButton {
            items.append(searchBarButtonItem)
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
        return !isCallOngoing
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
