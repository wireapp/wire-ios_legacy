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


extension ZMConversation: ShareDestination {
    
    public var showsGuestIcon: Bool {
        return ZMUser.selfUser().hasTeam &&
            self.conversationType == .oneOnOne &&
            self.activeParticipants.first {
                $0 is ZMUser && ($0 as! ZMUser).isGuest(in: self) } != nil
    }
    
    public var avatarView: UIView? {
        let avatarView = ConversationAvatarView()
        avatarView.conversation = self
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
        var cell: ConversationCell

        if isText {
            return ConversationTextMessageCellDescription.preview(for: self)
        }
        else if isImage {
            cell = ImageMessageCell(style: .default, reuseIdentifier: "")
        }
        else if isVideo {
            cell = VideoMessageCell(style: .default, reuseIdentifier: "")
        }
        else if isAudio {
            cell = AudioMessageCell(style: .default, reuseIdentifier: "")
        }
        else if isLocation {
            cell = LocationMessageCell(style: .default, reuseIdentifier: "")
        }
        else if isFile {
            cell = FileTransferCell(style: .default, reuseIdentifier: "")
        }
        else {
            fatal("Cannot create preview for \(type(of: self))")
        }
        
        cell.translatesAutoresizingMaskIntoConstraints = false
        let height = cell.prepareLayoutForPreview(message: self)
        
        constrain(cell.contentView) { cellContentView in
            cellContentView.height == height
        }
        
        cell.frame = CGRect(x: 0, y: 0, width: cell.frame.size.width, height: height)
        
        return cell
    }
}

extension ZMConversationList {
    func shareableConversations(excluding: ZMConversation? = nil) -> [ZMConversation] {
        return self.map { $0 as! ZMConversation }.filter { (conversation: ZMConversation) -> (Bool) in
            return (conversation.conversationType == .oneOnOne || conversation.conversationType == .group) &&
                conversation.isSelfAnActiveMember &&
                conversation != excluding
        }
    }
    
    func convesationsWhereBotCanBeAdded() -> [ZMConversation] {
        return self.shareableConversations().filter { $0.botCanBeAdded }
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
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? PopoverPresenter & UIViewController else { return }

        rootViewController.updatePopoverSourceRect()
    }
}

extension ConversationContentViewController: UIAdaptivePresentationControllerDelegate {

    @objc public func showForwardFor(message: ZMConversationMessage?, fromCell: ConversationCell?) {
        guard let message = message else { return }
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? PopoverPresenter & UIViewController else { return }

        view.window?.endEditing(true)
        
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
        
        if let popoverPresentationController = keyboardAvoiding.popoverPresentationController {
            if let cell = fromCell {
                popoverPresentationController.config(from: rootViewController,
                               pointToView: cell.selectionView,
                               sourceView: rootViewController.view)
            }

            popoverPresentationController.backgroundColor = UIColor(white: 0, alpha: 0.5)
            popoverPresentationController.permittedArrowDirections = [.left, .right]
        }
        
        keyboardAvoiding.presentationController?.delegate = self
        
        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>, _) -> () in
            shareController.presentingViewController?.dismiss(animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }

        rootViewController.present(keyboardAvoiding, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}

extension ConversationContentViewController {
    @objc func scroll(to messageToShow: ZMConversationMessage, completion: ((ConversationCell)->())? = .none) {
        guard messageToShow.conversation == self.conversation else {
            fatal("Message from the wrong conversation")
        }
        
        let indexInConversation: Int = self.conversation.messages.index(of: messageToShow)
        if !self.messageWindow.messages.contains(messageToShow) {
        
            let oldestMessageIndexInMessageWindow = self.conversation.messages.index(of: self.messageWindow.messages.firstObject!)
            let newestMessageIndexInMessageWindow = self.conversation.messages.index(of: self.messageWindow.messages.lastObject!)

            if oldestMessageIndexInMessageWindow > indexInConversation {
                self.messageWindow.moveUp(byMessages: UInt(oldestMessageIndexInMessageWindow - indexInConversation))
            }
            else {
                self.messageWindow.moveDown(byMessages: UInt(indexInConversation - newestMessageIndexInMessageWindow))
            }
        }

        let indexToShow = self.messageWindow.messages.index(of: messageToShow)

        if indexToShow == NSNotFound {
            self.expectedMessageToShow = messageToShow
            self.onMessageShown = completion
        }
        else {
            self.scroll(toIndex: indexToShow, completion: completion)
        }
    }
    
    @objc func scroll(toIndex indexToShow: Int, completion: ((ConversationCell)->())? = .none) {
        let cellIndexPath = IndexPath(row: indexToShow, section: 0)

        self.tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: false)
        if let cell = self.tableView.cellForRow(at: cellIndexPath) as? ConversationCell {
            completion?(cell)
        }
    }
}
