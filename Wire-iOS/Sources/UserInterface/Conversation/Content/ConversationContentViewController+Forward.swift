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

import Foundation
import WireSyncEngine
import WireCommonComponents
import UIKit

extension ZMConversation: ShareDestination {

    var showsGuestIcon: Bool {
        return ZMUser.selfUser().hasTeam &&
            self.conversationType == .oneOnOne &&
            self.localParticipants.first {
                $0.isGuest(in: self) } != nil
    }

}

extension ShareDestination where Self: ConversationAvatarViewConversation {
    var avatarView: UIView? {
        let avatarView = ConversationAvatarView()
        avatarView.configure(context: .conversation(conversation: self))
        return avatarView
    }
}

extension Array where Element == ZMConversation {

    // Should be called inside ZMUserSession.shared().perform block
    func forEachNonEphemeral(_ block: (ZMConversation) -> Void) {
        forEach {
            guard let timeout = $0.activeMessageDestructionTimeoutValue,
                  let type = $0.activeMessageDestructionTimeoutType else {
                return
            }
            $0.setMessageDestructionTimeoutValue(.init(rawValue: 0), for: type)
            block($0)
            $0.setMessageDestructionTimeoutValue(timeout, for: type)
        }
    }
}

extension ZMMessage: Shareable {
    typealias I = ZMConversation

    func share<ZMConversation>(to: [ZMConversation]) {
        forward(to: to as [AnyObject])
    }

    func forward(to: [AnyObject]) {

        let conversations = to as! [ZMConversation]

        if isText {
            let fetchLinkPreview = !Settings.disableLinkPreviews
            ZMUserSession.shared()?.perform {
                conversations.forEachNonEphemeral {
                    do {
                        // We should not forward any mentions to other conversations
                        try $0.appendText(content: self.textMessageData!.messageText!, mentions: [], fetchLinkPreview: fetchLinkPreview)
                    } catch {
                        Logging.messageProcessing.warn("Failed to append text message. Reason: \(error.localizedDescription)")
                    }
                }
            }
        } else if isImage, let imageData = imageMessageData?.imageData {
            ZMUserSession.shared()?.perform {
                conversations.forEachNonEphemeral {
                    do {
                        try $0.appendImage(from: imageData)
                    } catch {
                        Logging.messageProcessing.warn("Failed to append image message. Reason: \(error.localizedDescription)")
                    }
                }
            }
        } else if isVideo || isAudio || isFile {
            let url  = fileMessageData!.fileURL!
            FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI(), name: url.lastPathComponent) { fileMetadata in
                ZMUserSession.shared()?.perform {
                    conversations.forEachNonEphemeral {
                        do {
                            try $0.appendFile(with: fileMetadata)
                        } catch {
                            Logging.messageProcessing.warn("Failed to append file message. Reason: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else if isLocation {
            let locationData = LocationData.locationData(withLatitude: locationMessageData!.latitude, longitude: locationMessageData!.longitude, name: locationMessageData!.name, zoomLevel: locationMessageData!.zoomLevel)
            ZMUserSession.shared()?.perform {
                conversations.forEachNonEphemeral {
                    do {
                        try $0.appendLocation(with: locationData)
                    } catch {
                        Logging.messageProcessing.warn("Failed to append location message. Reason: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            fatal("Cannot forward message")
        }
    }

}

extension ZMConversationMessage {
    func previewView() -> UIView? {
        let view = preparePreviewView(shouldDisplaySender: false)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }
}

extension ZMConversationList {/// TODO mv to DM
    func shareableConversations(excluding: ConversationLike? = nil) -> [ZMConversation] {
        return map { $0 as! ZMConversation }.filter { (conversation: ZMConversation) -> (Bool) in
            return (conversation.conversationType == .oneOnOne || conversation.conversationType == .group) &&
                conversation.isSelfAnActiveMember &&
                !(conversation === excluding)
        }
    }
}

// MARK: - popover apperance update

extension ConversationContentViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }

        if let keyboardAvoidingViewController = self.presentedViewController as? KeyboardAvoidingViewController,
           let shareViewController = keyboardAvoidingViewController.viewController as? ShareViewController<ZMConversation, ZMMessage> {
            shareViewController.showPreview = traitCollection.horizontalSizeClass != .regular
        }

        updatePopoverSourceRect()
    }

    func updatePopover() {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? PopoverPresenterViewController else { return }

        rootViewController.updatePopoverSourceRect()
    }
}

extension ConversationContentViewController: UIAdaptivePresentationControllerDelegate {

    func showForwardFor(message: ZMConversationMessage?, from view: UIView?) {
        guard let userSession = ZMUserSession.shared(),
              let message = message else { return }

        endEditing()

        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession ).shareableConversations(excluding: message.conversationLike)

        let shareViewController = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message as! ZMMessage,
            destinations: conversations,
            showPreview: traitCollection.horizontalSizeClass != .regular
        )

        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)
        keyboardAvoiding.disabledWhenInsidePopover = true
        keyboardAvoiding.preferredContentSize = CGSize.IPadPopover.preferredContentSize
        keyboardAvoiding.modalPresentationCapturesStatusBarAppearance = true

        let presenter: PopoverPresenterViewController? = (presentedViewController ?? UIApplication.shared.keyWindow?.rootViewController) as? PopoverPresenterViewController

        if let presenter = presenter,
           let pointToView = (view as? SelectableView)?.selectionView ?? view ?? self.view {
            keyboardAvoiding.configPopover(pointToView: pointToView, popoverPresenter: presenter)
        }

        if let popoverPresentationController = keyboardAvoiding.popoverPresentationController {
            popoverPresentationController.backgroundColor = UIColor(white: 0, alpha: 0.5)
        }

        keyboardAvoiding.presentationController?.delegate = self

        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>, _) -> Void in
            weak var presentingViewController = shareController.presentingViewController

            presentingViewController?.dismiss(animated: true)
        }

        (presenter ?? self).present(keyboardAvoiding, animated: true)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}
