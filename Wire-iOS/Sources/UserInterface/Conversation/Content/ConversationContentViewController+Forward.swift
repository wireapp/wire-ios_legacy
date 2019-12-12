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
import Cartography
import WireCommonComponents

extension ZMConversation: ShareDestination {
    
    public var showsGuestIcon: Bool {
        return ZMUser.selfUser().hasTeam &&
            self.conversationType == .oneOnOne &&
            self.localParticipants.first {
                $0.isGuest(in: self) } != nil
    }
    
    public var avatarView: UIView? {
        let avatarView = ConversationAvatarView()
        avatarView.configure(context: .conversation(conversation: self))
        return avatarView
    }
}

extension Array where Element == ZMConversation {

    // Should be called inside ZMUserSession.shared().performChanges block
    func forEachNonEphemeral(_ block: (ZMConversation) -> Void) {
        forEach {
            let timeout = $0.messageDestructionTimeout
            $0.messageDestructionTimeout = nil
            block($0)
            $0.messageDestructionTimeout = timeout
        }
    }
}

func forward(_ message: ZMMessage, to: [AnyObject]) {

    let conversations = to as! [ZMConversation]
    
    if message.isText {
        let fetchLinkPreview = !Settings.shared().disableLinkPreviews
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral {
                // We should not forward any mentions to other conversations
                _ = $0.append(text: message.textMessageData!.messageText!, mentions: [], fetchLinkPreview: fetchLinkPreview)
            }
        }
    }
    else if message.isImage, let imageData = message.imageMessageData?.imageData {
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.append(imageFromData: imageData) }
        }
    }
    else if message.isVideo || message.isAudio || message.isFile {
        let url  = message.fileMessageData!.fileURL!
        FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI(), name: url.lastPathComponent) { fileMetadata in
            ZMUserSession.shared()?.performChanges {
                conversations.forEachNonEphemeral { _ = $0.append(file: fileMetadata) }
            }
        }
    }
    else if message.isLocation {
        let locationData = LocationData.locationData(withLatitude: message.locationMessageData!.latitude, longitude: message.locationMessageData!.longitude, name: message.locationMessageData!.name, zoomLevel: message.locationMessageData!.zoomLevel)
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.append(location: locationData) }
        }
    }
    else {
        fatal("Cannot forward message")
    }
}

extension ZMMessage: Shareable {
    
    public func share<ZMConversation>(to: [ZMConversation]) {
        forward(self, to: to as [AnyObject])
    }
    
    public typealias I = ZMConversation
    
    
}

extension ZMConversationMessage {
    public func previewView() -> UIView? {
        let view = self.preparePreviewView(shouldDisplaySender: false)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }
}

extension ZMConversationList {///TODO mv to DM
    func shareableConversations(excluding: ZMConversation? = nil) -> [ZMConversation] {
        return self.map { $0 as! ZMConversation }.filter { (conversation: ZMConversation) -> (Bool) in
            return (conversation.conversationType == .oneOnOne || conversation.conversationType == .group) &&
                conversation.isSelfAnActiveMember &&
                conversation != excluding
        }
    }
}

// MARK: - popover apperance update

extension ConversationContentViewController {

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }


        if let keyboardAvoidingViewController = self.presentedViewController as? KeyboardAvoidingViewController,
           let shareViewController = keyboardAvoidingViewController.viewController as? ShareViewController<ZMConversation, ZMMessage> {
            shareViewController.showPreview = traitCollection.horizontalSizeClass != .regular
        }
    }

    @objc func updatePopover() {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? PopoverPresenterViewController else { return }

        rootViewController.updatePopoverSourceRect()
    }
}

extension ConversationContentViewController: UIAdaptivePresentationControllerDelegate {

    func showForwardFor(message: ZMConversationMessage?, from view: UIView?) {
        guard let message = message else { return }

        endEditing()
        
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!).shareableConversations(excluding: message.conversation!)

        let shareViewController = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message as! ZMMessage,
            destinations: conversations,
            showPreview: traitCollection.horizontalSizeClass != .regular
        )

        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)
        
        keyboardAvoiding.shouldAdjustFrame = { controller in
            // We do not want to adjust the keyboard frame when we are being presented in a popover.
            controller.popoverPresentationController?.arrowDirection == .unknown
        }
        
        keyboardAvoiding.preferredContentSize = CGSize.IPadPopover.preferredContentSize
        keyboardAvoiding.modalPresentationStyle = .popover

        let presenter: PopoverPresenterViewController? = (self.presentedViewController ?? UIApplication.shared.keyWindow?.rootViewController) as? PopoverPresenterViewController

        if let pointToView = (view as? SelectableView)?.selectionView ?? view ?? self.view {
            keyboardAvoiding.configPopover(pointToView: pointToView, popoverPresenter: presenter)
        }

        if let popoverPresentationController = keyboardAvoiding.popoverPresentationController {
            popoverPresentationController.backgroundColor = UIColor(white: 0, alpha: 0.5)
        }
        
        keyboardAvoiding.presentationController?.delegate = self
        
        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>, _) -> () in
            shareController.presentingViewController?.dismiss(animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }


        (presenter ?? self).present(keyboardAvoiding, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}
