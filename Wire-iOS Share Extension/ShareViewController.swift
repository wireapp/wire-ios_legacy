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
import Social
import WireShareEngine
import Cartography
import MobileCoreServices
import ZMCDataModel
import WireExtensionComponents
import Classy


var globSharingSession : SharingSession? = nil

class ShareViewController: SLComposeServiceViewController {
    
    var conversationItem : SLComposeSheetConfigurationItem?
    var selectedConversation : Conversation?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.appendURLIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func presentationAnimationDidFinish() {
        let bundle = Bundle.main
        
        if let applicationGroupIdentifier = bundle.infoDictionary?["ApplicationGroupIdentifier"] as? String,
            let hostBundleIdentifier = bundle.infoDictionary?["HostBundleIdentifier"] as? String,
            globSharingSession == nil {
                globSharingSession = try? SharingSession(applicationGroupIdentifier: applicationGroupIdentifier, hostBundleIdentifier: hostBundleIdentifier)
            }
    
        guard let sharingSession = globSharingSession, sharingSession.canShare else {
            presentNotSignedInMessage()
            return
        }
    }
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return globSharingSession != nil && selectedConversation != nil
    }

    override func didSelectPost() {
        send { [weak self] (messages) in
            self?.presentSendingProgress(forMessages: messages)
        }
    }
    
    /// If there is a URL attachment, copy the text of the URL attachment into the text field
    private func appendURLIfNeeded() {
        guard self.textView.text.isEmpty else { return } // do not append if the title is already there
        self.fetchURLAttachments { (urls) in
            guard let url = urls.first else { return }
            DispatchQueue.main.async {
                if !url.isFileURL { // remote URL (not local file)
                    if self.textView.text.isEmpty {
                        self.placeholder = url.absoluteString // suggest
                    }
                }
            }
        }
    }
    
    /// Generates the preview image
    override func loadPreviewView() -> UIView! {
        return UIImageView(image: UIImage(for: .document, iconSize: .large, color: UIColor.black))
    }
    
    override func configurationItems() -> [Any]! {
        let conversationItem = SLComposeSheetConfigurationItem()!
        self.conversationItem = conversationItem
        
        conversationItem.title = "Share to:"
        conversationItem.value = "None"
        conversationItem.tapHandler = { [weak self] in
             self?.selectConversation()
        }
        
        return [conversationItem]
    }
    
    private func presentSendingProgress(forMessages messages: [Sendable]) {
        let progressViewController = SendingProgressViewController(messages: messages)
        
        progressViewController.cancelHandler = { [weak self] in
            self?.cancel()
        }
        
        progressViewController.sentHandler = { [weak self] in
            self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
        
        pushConfigurationViewController(progressViewController)
    }
    
    private func presentNotSignedInMessage() {
        let notSignedInViewController = NotSignedInViewController()
        
        notSignedInViewController.closeHandler = { [weak self] in
            self?.cancel()
        }
        
        pushConfigurationViewController(notSignedInViewController)
    }
    
    private func selectConversation() {
        guard let sharingSession = globSharingSession else { return }

        let allConversations = sharingSession.writeableNonArchivedConversations + sharingSession.writebleArchivedConversations
        let conversationSelectionViewController = ConversationSelectionViewController(conversations: allConversations)
        
        conversationSelectionViewController.selectionHandler = { [weak self] conversation in
            self?.conversationItem?.value = conversation.name
            self?.selectedConversation = conversation
            self?.popConfigurationViewController()
            self?.validateContent()
        }
        
        pushConfigurationViewController(conversationSelectionViewController)
    }
}

// MARK: - Manage attachements
extension ShareViewController {
    
    /// Get all the attachments to this post
    fileprivate var attachments : [NSItemProvider] {
        guard let extensionContext = extensionContext else { return [] }
        return extensionContext.inputItems
            .flatMap { $0 as? [NSExtensionItem] } // remove optional
            .flatMap { $0 } // flattens array
            .flatMap { $0.attachments as? [NSItemProvider] } // remove optional
            .flatMap { $0 } // flattens array
    }
    
    /// Gets all the URLs in this post, and invoke the callback (on main queue) when done
    fileprivate func fetchURLAttachments(callback: @escaping ([URL])->()) {
        var urls : [URL] = []
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "share extension URLs queue")
        
        self.attachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, urlCompletionHandler: { (url, error) in
                    defer { group.leave() }
                    guard let url = url, error == nil else { return }
                    queue.async {
                        urls.append(url)
                    }
                })
            }
        }
        group.notify(queue: queue) { _ in callback(urls) }
    }
}


// MARK: - Send attachments
extension ShareViewController {
    
    /// Send the content to the selected conversation
    fileprivate func send(sentCompletionHandler: @escaping ([Sendable]) -> Void) {
        
        let sendingGroup = DispatchGroup()
        sendingGroup.enter()
        
        guard let conversation = self.selectedConversation,
            let sharingSession = globSharingSession else {
                sentCompletionHandler([])
                return
        }
        
        var messages : [Sendable] = [] // this will be modified from another thread, the sync thread,
                                        // but we won't read until we are done modifying it so
                                        // it's safe to access this from this thread again
        self.sendAttachments(sharingSession: sharingSession,
                  conversation: conversation,
                  group: sendingGroup) { $0.flatMap { messages.append($0) } }
        
        if !self.contentText.isEmpty {
            sendingGroup.enter()
            sharingSession.enqueue {
                if let message = conversation.appendTextMessage(self.contentText) {
                    messages.append(message)
                }
                sendingGroup.leave()
            }
        }
        
        sendingGroup.notify(queue: .main) {
            DispatchQueue.main.async {
                sentCompletionHandler(messages)
            }
        }
    }
    
    /// Send all attachments
    fileprivate func sendAttachments(sharingSession: SharingSession,
                          conversation: Conversation,
                          group: DispatchGroup,
                          newSendableCreated: @escaping (Sendable?)->()) {
        
        self.attachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                self.sendAsImage(conversation: conversation, attachment: attachment, group: group, newSendableCreated: newSendableCreated)
            }
            else if attachment.hasItemConformingToTypeIdentifier(kUTTypeData as String) {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) { // if it has a URL, is it a local URL or a remote one?
                                                                                        // because if it's remote I should send link, not file
                    attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, urlCompletionHandler: { (url, error) in
                        guard let url = url, error == nil else { return }
                        if url.isFileURL {
                            self.sendAsFile(conversation: conversation, attachment: attachment, group: group, newSendableCreated: newSendableCreated)
                        } else {
                            // do not send. It is a remote URL and will be sent as a link
                        }
                    })
                    
                } else {
                    self.sendAsFile(conversation: conversation, attachment: attachment, group: group, newSendableCreated: newSendableCreated)
                }
            }
        }
        
        group.leave()
    }
    
    /// Appends a file message, and invokes the callback when the message is available
    fileprivate func sendAsFile(conversation: Conversation, attachment: NSItemProvider, group: DispatchGroup, newSendableCreated: @escaping (Sendable?)->()) {
        
        attachment.loadItem(forTypeIdentifier: kUTTypeData as String, options: [:], dataCompletionHandler: { (data, error) in
            
            guard let data = data,
                let UTIString = attachment.registeredTypeIdentifiers.first as? String,
                error == nil else {
                    newSendableCreated(nil)
                    return
            }
            
            self.prepareForSending(data:data, UTIString: UTIString) { url, error in
                guard let url = url,
                    let sharingSession = globSharingSession,
                    error == nil else {
                        newSendableCreated(nil)
                        return
                }
                group.enter()
                DispatchQueue.main.async {
                    FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI()) { metadata -> Void in
                        sharingSession.enqueue {
                            if let message = conversation.appendFile(metadata) {
                                newSendableCreated(message)
                            }
                            group.leave()
                        }
                    }
                }
            }
        })
    }
    
    /// Appends an image message, and invokes the callback when the message is available
    fileprivate func sendAsImage(conversation: Conversation, attachment: NSItemProvider, group: DispatchGroup, newSendableCreated: @escaping (Sendable?)->()) {
        let preferredSize = NSValue.init(cgSize: CGSize(width: 1024, height: 1024))
        attachment.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], imageCompletionHandler: { (image, error) in
            guard let image = image,
                let sharingSession = globSharingSession,
                let imageData = UIImageJPEGRepresentation(image, 0.9),
                error == nil else {
                    newSendableCreated(nil)
                    return
            }

            group.enter()
            DispatchQueue.main.async {
                sharingSession.enqueue {
                    if let message = conversation.appendImage(imageData) {
                        newSendableCreated(message)
                    }
                    group.leave()
                }
            }
        })
    }
    
    /// Process data to the right format to be sent
    private func prepareForSending(data: Data, UTIString UTI: String, completionHandler: @escaping (URL?, Error?)->Void ) {
        let fileExtension = UTTypeCopyPreferredTagWithClass(UTI as CFString, kUTTagClassFilenameExtension as CFString)?.takeRetainedValue() as! String
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
        if FileManager.default.fileExists(atPath: tempFileURL.absoluteString) {
            try! FileManager.default.removeItem(at: tempFileURL)
        }
        do {
            try data.write(to: tempFileURL)
        } catch {
            completionHandler(nil, NSError())
            return
        }
        
        
        if UTTypeConformsTo(UTI as CFString, kUTTypeMovie) {
            AVAsset.wr_convertVideo(at: tempFileURL) { (url, _, error) in
                completionHandler(url, error)
            }
        } else {
            completionHandler(tempFileURL, nil)
        }
    }
}
