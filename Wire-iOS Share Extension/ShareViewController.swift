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
        
        if let rightButtonBarItem = navigationController?.navigationBar.items?.first?.rightBarButtonItem {
            rightButtonBarItem.action = #selector(appendPostTapped)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func presentationAnimationDidFinish() {
        let bundle = Bundle.main
        
        if let applicationGroupIdentifier = bundle.infoDictionary?["ApplicationGroupIdentifier"] as? String, let hostBundleIdentifier = bundle.infoDictionary?["HostBundleIdentifier"] as? String, globSharingSession == nil {
            
                globSharingSession = try? SharingSession(applicationGroupIdentifier: applicationGroupIdentifier, hostBundleIdentifier: hostBundleIdentifier)
            }
        
    
        guard let sharingSession = globSharingSession, sharingSession.canShare else {
            presentNotSignedInMessage()
            return
        }
    }
    
    func appendPostTapped() {
        sendShareable { [weak self] (messages) in
            self?.presentSendingProgress(forMessages: messages)
        }
    }
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return globSharingSession != nil && selectedConversation != nil
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        if let sharingSession = globSharingSession, let conversation = selectedConversation {
            sharingSession.enqueue(changes: { 
                _ = conversation.appendTextMessage(self.contentText)
            })
        }
    }
    
    
    private func sendShareable(sentCompletionHandler: @escaping ([Sendable]) -> Void) {
        
        var messages : [Sendable] = []
        
        let sendingGroup = DispatchGroup()
        
        guard let conversation = self.selectedConversation,
            let sharingSession = globSharingSession
        else {
            sentCompletionHandler([])
            return
        }
        
        let attachments = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        self.send(sharingSession: sharingSession,
                  conversation: conversation,
                  attachments: attachments,
                  group: sendingGroup,
                  text: self.contentText) { $0.flatMap { messages.append($0) } }
        
        sendingGroup.notify(queue: .main) {
            sentCompletionHandler(messages)
        }
    }

    
    override func didReceiveMemoryWarning() {
        // pass
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

        let conversationSelectionViewController = ConversationSelectionViewController(conversations: sharingSession.writeableNonArchivedConversations)
        
        conversationSelectionViewController.selectionHandler = { [weak self] conversation in
            self?.conversationItem?.value = conversation.name
            self?.selectedConversation = conversation
            self?.popConfigurationViewController()
            self?.validateContent()
        }
        
        pushConfigurationViewController(conversationSelectionViewController)
    }
}

// MARK: - Send attachments
extension ShareViewController {
    
    fileprivate func send(sharingSession: SharingSession,
                          conversation: Conversation,
                          attachments: [NSExtensionItem],
                          group: DispatchGroup,
                          text: String,
                          newSendable: @escaping (Sendable?)->()) {
        
        group.enter()
        
        var shouldSendText = true
        attachments.forEach { inputItem in
            
            if let attachments = inputItem.attachments as? [NSItemProvider] {
                
                let hasImageAttachment = !attachments.filter { $0.hasItemConformingToTypeIdentifier(kUTTypeImage as String) }.isEmpty
                for attachment in attachments {
                    
                    if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                        self.sendAsImage(conversation: conversation, attachment: attachment, group: group, newSendable: newSendable)
                    }
                    else if !hasImageAttachment && attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                        self.sendAsURL(additionalText: text, conversation: conversation, attachment: attachment, group: group, newSendable: newSendable)
                        shouldSendText = false
                    }
                    else if attachment.hasItemConformingToTypeIdentifier(kUTTypeData as String) {
                        self.sendAsFile(conversation: conversation, attachment: attachment, group: group, newSendable: newSendable)
                    }
                }
            }
        }
        
        if shouldSendText && !text.isEmpty {
            group.enter()
            sharingSession.enqueue {
                if let message = conversation.appendTextMessage(text) {
                    newSendable(message)
                }
                group.leave()
            }
        }
        
        group.leave()
    }
    
    /// Appends a file message, and invokes the callback when the message is available
    fileprivate func sendAsFile(conversation: Conversation, attachment: NSItemProvider, group: DispatchGroup, newSendable: @escaping (Sendable?)->()) {
        group.enter()
        
        attachment.loadItem(forTypeIdentifier: kUTTypeData as String, options: [:], dataCompletionHandler: { (data, error) in
            
            guard let data = data,
                let UTIString = attachment.registeredTypeIdentifiers.first as? String,
                error == nil else {
                    
                    group.leave()
                    return
            }
            
            self.process(data:data, UTIString: UTIString) { url, error in
                guard let url = url,
                    let sharingSession = globSharingSession,
                    error == nil else {
                        newSendable(nil)
                        group.leave()
                        return
                }
                DispatchQueue.main.async {
                    FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI()) { metadata -> Void in
                        sharingSession.enqueue {
                            if let message = conversation.appendFile(metadata) {
                                newSendable(message)
                            }
                            group.leave()
                        }
                    }
                }
            }
        })
    }
    
    /// Appends an image message, and invokes the callback when the message is available
    fileprivate func sendAsImage(conversation: Conversation, attachment: NSItemProvider, group: DispatchGroup, newSendable: @escaping (Sendable?)->()) {
        group.enter()
        let preferredSize = NSValue.init(cgSize: CGSize(width: 1024, height: 1024))
        attachment.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], imageCompletionHandler: { (image, error) in
            guard let image = image,
                let sharingSession = globSharingSession,
                let imageData = UIImageJPEGRepresentation(image, 0.9),
                error == nil else {
                    newSendable(nil)
                    group.leave()
                    return
            }
            
            DispatchQueue.main.async {
                sharingSession.enqueue {
                    if let message = conversation.appendImage(imageData) {
                        newSendable(message)
                    }
                    group.leave()
                }
            }
        })
    }
    
    /// Appends a URL message, and invokes the callback when the message is available
    fileprivate func sendAsURL(additionalText: String, conversation: Conversation, attachment: NSItemProvider, group: DispatchGroup, newSendable: @escaping (Sendable?)->()) {
        group.enter()
        attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, urlCompletionHandler: { (url, error) in

            guard let url = url,
                let sharingSession = globSharingSession,
                error == nil else {
                    newSendable(nil)
                    group.leave()
                    return
            }
            let text = additionalText + (additionalText.isEmpty ? "" : "\n") + url.absoluteString
            
            DispatchQueue.main.async {
                sharingSession.enqueue {
                    if let message = conversation.appendTextMessage(text) {
                        newSendable(message)
                    }
                    group.leave()
                }
            }
        })
    }
    
    private func process(data: Data, UTIString UTI: String, completionHandler: @escaping (URL?, Error?)->Void ) {
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
