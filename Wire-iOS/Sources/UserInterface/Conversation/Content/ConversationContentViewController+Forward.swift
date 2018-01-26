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
            let timeout = $0.destructionTimeout
            $0.updateMessageDestructionTimeout(timeout: .none)
            block($0)
            $0.updateMessageDestructionTimeout(timeout: timeout)
        }
    }
}

func forward(_ message: ZMMessage, to: [AnyObject]) {

    let conversations = to as! [ZMConversation]
    
    if message.isText {
        let fetchLinkPreview = !Settings.shared().disableLinkPreviews
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.appendMessage(withText: message.textMessageData!.messageText, fetchLinkPreview: fetchLinkPreview) }
        }
    }
    else if message.isImage {
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.appendMessage(withImageData: message.imageMessageData!.imageData) }
        }
    }
    else if message.isVideo || message.isAudio || message.isFile {
        let url  = message.fileMessageData!.fileURL!
        FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI(), name: url.lastPathComponent) { fileMetadata in
            ZMUserSession.shared()?.performChanges {
                conversations.forEachNonEphemeral { _ = $0.appendMessage(with: fileMetadata) }
            }
        }
    }
    else if message.isLocation {
        let locationData = LocationData.locationData(withLatitude: message.locationMessageData!.latitude, longitude: message.locationMessageData!.longitude, name: message.locationMessageData!.name, zoomLevel: message.locationMessageData!.zoomLevel)
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.appendMessage(with: locationData) }
        }
    }
    else {
        fatal("Cannot forward \(message)")
    }
}

extension ZMMessage: Shareable {
    
    public func share<ZMConversation>(to: [ZMConversation]) {
        forward(self, to: to as [AnyObject])
    }
    
    public typealias I = ZMConversation
    
    public func previewView() -> UIView? {
        var cell: ConversationCell
        
        if isText {
            cell = TextMessageCell(style: .default, reuseIdentifier: "")
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
            fatal("Cannot create preview for \(self)")
        }
        
        let height = cell.prepareLayoutForPreview(message: self)
        
        cell.translatesAutoresizingMaskIntoConstraints = false
        
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
}

extension ConversationContentViewController: UIAdaptivePresentationControllerDelegate {
    @objc public func showForwardFor(message: ZMConversationMessage?, fromCell: ConversationCell?) {
        guard let message = message else { return }

        if let window = self.view.window {
            window.endEditing(true)
        }
        
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!).shareableConversations(excluding: message.conversation!)

        let shareViewController = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message as! ZMMessage,
            destinations: conversations,
            showPreview: traitCollection.horizontalSizeClass != .regular
        )

        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)
        
        keyboardAvoiding.preferredContentSize = CGSize(width: 320, height: 568)
        keyboardAvoiding.modalPresentationStyle = .popover
        
        if let popoverPresentationController = keyboardAvoiding.popoverPresentationController {
            if let cell = fromCell {
                popoverPresentationController.sourceRect = cell.selectionRect
                popoverPresentationController.sourceView = cell.selectionView
            }
            popoverPresentationController.backgroundColor = UIColor(white: 0, alpha: 0.5)
            popoverPresentationController.permittedArrowDirections = [.up, .down]
        }
        
        keyboardAvoiding.presentationController?.delegate = self
        
        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>, _) -> () in
            shareController.presentingViewController?.dismiss(animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(keyboardAvoiding, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}

extension ConversationContentViewController {
    func scroll(to messageToShow: ZMConversationMessage, completion: ((ConversationCell)->())? = .none) {
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
    
    func scroll(toIndex indexToShow: Int, completion: ((ConversationCell)->())? = .none) {
        let cellIndexPath = IndexPath(row: indexToShow, section: 0)
        self.tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: false)
        
        delay(0.1) {
            completion?(self.tableView.cellForRow(at: cellIndexPath) as! ConversationCell)
        }
    }
}
