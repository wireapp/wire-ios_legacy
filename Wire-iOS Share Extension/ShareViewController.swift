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

/// The delay after which a progess view controller will be displayed if all messages are not yet sent.
private let progressDisplayDelay: TimeInterval = 0.5


class ShareViewController: SLComposeServiceViewController {
    
    var conversationItem : SLComposeSheetConfigurationItem?
    var selectedConversation : Conversation?

    private var observer: SendableBatchObserver? = nil
    private weak var progressViewController: SendingProgressViewController? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let rightButtonBarItem = navigationController?.navigationBar.items?.first?.rightBarButtonItem {
            rightButtonBarItem.action = #selector(appendPostTapped)
        }
        
        self.appendURLIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        observer = nil
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

    /// invoked when the user wants to post
    func appendPostTapped() {

        send { [weak self] (messages) in
            guard let `self` = self else { return }
            self.observer = SendableBatchObserver(sendables: messages)
            self.observer?.progressHandler = {
                self.progressViewController?.progress = $0
            }
            
            self.observer?.sentHandler = {
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                guard self.observer?.allSendablesSent == false else { return }
                self.presentSendingProgress()
            }
        }
    }
    
    
    /// Display a preview image
    override func loadPreviewView() -> UIView! {
        let parentView : UIView? = super.loadPreviewView()
        return parentView ?? UIImageView(image: UIImage(for: .document, iconSize: .large, color: UIColor.black))
    }

    /// If there is a URL attachment, copy the text of the URL attachment into the text field
    private func appendURLIfNeeded() {
        guard self.textView.text.isEmpty else { return } // do not append if the title is already there
        self.fetchURLAttachments { (urls) in
            guard let url = urls.first else { return }
            DispatchQueue.main.async {
                if !url.isFileURL { // remote URL (not local file)
                    if self.textView.text.isEmpty {
                        self.placeholder = url.host // suggest
                    }
                } else {
                    if self.textView.text.isEmpty {
                        self.placeholder = url.lastPathComponent
                    }
                }
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        let conversationItem = SLComposeSheetConfigurationItem()!
        self.conversationItem = conversationItem
        
        conversationItem.title = "share_extension.conversation_selection.title".localized
        conversationItem.value = "share_extension.conversation_selection.empty.value".localized
        conversationItem.tapHandler = { [weak self] in
             self?.presentChooseConversation()
        }
        
        return [conversationItem]
    }
    
    private func presentSendingProgress() {
        let progressSendingViewController = SendingProgressViewController()
        
        progressSendingViewController.cancelHandler = { [weak self] in
            guard let `self` = self else { return }

            let sendablesToCancel = self.observer?.sendables.lazy.filter {
                $0.deliveryState != .sent && $0.deliveryState != .delivered
            }

            globSharingSession?.enqueue {
                sendablesToCancel?.forEach {
                    $0.cancel()
                }
            }

            self.cancel()
        }

        progressViewController = progressSendingViewController
        pushConfigurationViewController(progressSendingViewController)
    }
    
    private func presentNotSignedInMessage() {
        let notSignedInViewController = NotSignedInViewController()
        
        notSignedInViewController.closeHandler = { [weak self] in
            self?.cancel()
        }
        
        pushConfigurationViewController(notSignedInViewController)
    }
    
    private func presentChooseConversation() {
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


// MARK: - Send attachments
extension ShareViewController {
    
    /// Send the content to the selected conversation
    fileprivate func send(sentCompletionHandler: @escaping ([Sendable]) -> Void) {
        
        guard let conversation = self.selectedConversation,
            let sharingSession = globSharingSession else {
                sentCompletionHandler([])
                return
        }
        
        
        self.sendAttachments(sharingSession: sharingSession,
                  conversation: conversation,
                  text: self.contentText,
                  completionHandler: sentCompletionHandler)
    }
    
    /// Send all attachments
    fileprivate func sendAttachments(sharingSession: SharingSession,
                          conversation: Conversation,
                          text: String,
                          completionHandler: @escaping ([Sendable])->()) {
        
        let sendingGroup = DispatchGroup()
        
        var messages : [Sendable] = [] // this will always modifed on the main thread
        
        let completeAndAppendToMessages : (Sendable?)->() = { sendable in
            defer { sendingGroup.leave() }
            guard let sendable = sendable else {
                return
            }
            DispatchQueue.main.async {
                messages.append(sendable)
            }
        }
        
        var finalText = text
        self.attachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                sendingGroup.enter()
                self.sendAsImage(sharingSession: sharingSession, conversation: conversation, attachment: attachment, completionHandler: completeAndAppendToMessages)
            }
            else if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                sendingGroup.enter()
                attachment.fetchURL { url in
                    if let url = url, !url.isFileURL == true { // remote URL, send as link
                        let separator = finalText.isEmpty ? "" : "\n"
                        finalText += separator + url.absoluteString
                        sendingGroup.leave()
                    } else if attachment.hasItemConformingToTypeIdentifier(kUTTypeData as String) {
                        self.sendAsFile(sharingSession: sharingSession, conversation: conversation, name: url?.lastPathComponent, attachment: attachment, completionHandler: completeAndAppendToMessages)
                    }
                }
            }
            else if attachment.hasItemConformingToTypeIdentifier(kUTTypeData as String) {
                sendingGroup.enter()
                self.sendAsFile(sharingSession: sharingSession, conversation: conversation, name: nil, attachment: attachment, completionHandler: completeAndAppendToMessages)
            }
        }
        

        
        sendingGroup.notify(queue: .main) {
            
            if !finalText.isEmpty {
                sendingGroup.enter()
                self.sendAsText(sharingSession: sharingSession, conversation: conversation, text: finalText, completionHandler: completeAndAppendToMessages)
            }
            
            sendingGroup.notify(queue: .main) {
                DispatchQueue.main.async {
                    completionHandler(messages)
                }
            }
        }
    }
    
    /// Appends a file message, and invokes the callback when the message is available
    fileprivate func sendAsFile(sharingSession: SharingSession, conversation: Conversation, name: String?, attachment: NSItemProvider, completionHandler: @escaping (Sendable?)->()) {
        
        attachment.loadItem(forTypeIdentifier: kUTTypeData as String, options: [:], dataCompletionHandler: { (data, error) in

            guard let data = data,
                let UTIString = attachment.registeredTypeIdentifiers.first as? String,
                error == nil else {
                    DispatchQueue.main.async {
                        completionHandler(nil)
                    }
                    return
            }
            
            self.prepareForSending(data:data, UTIString: UTIString) { url, error in
                
                DispatchQueue.main.async {
                    guard let url = url,
                        error == nil else {
                            completionHandler(nil)
                            return
                    }

                    FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI(), name: name ?? url.lastPathComponent) { metadata -> Void in
                        sharingSession.enqueue {
                            if let message = conversation.appendFile(metadata) {
                                completionHandler(message)
                            } else {
                                completionHandler(nil)
                            }
                        }
                    }
                }
            }
        })
    }
    
    /// Appends an image message, and invokes the callback when the message is available
    fileprivate func sendAsImage(sharingSession: SharingSession, conversation: Conversation, attachment: NSItemProvider, completionHandler: @escaping (Sendable?)->()) {
        let preferredSize = NSValue.init(cgSize: CGSize(width: 1024, height: 1024))
        attachment.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], imageCompletionHandler: { (image, error) in
            DispatchQueue.main.async {
                guard let image = image,
                    let imageData = UIImageJPEGRepresentation(image, 0.9),
                    error == nil else {
                        completionHandler(nil)
                        return
                }
                
                sharingSession.enqueue {
                    if let message = conversation.appendImage(imageData) {
                        completionHandler(message)
                    } else {
                        completionHandler(nil)
                    }
                }
            }
        })
    }
    
    /// Appends an image message, and invokes the callback when the message is available
    fileprivate func sendAsText(sharingSession: SharingSession, conversation: Conversation, text: String, completionHandler: @escaping (Sendable?)->()) {
        DispatchQueue.main.async {
            sharingSession.enqueue {
                if let message = conversation.appendTextMessage(text) {
                    completionHandler(message)
                } else {
                    completionHandler(nil)
                }
            }
        }
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

// MARK: - Process attachements
extension ShareViewController {
    
    /// Get all the attachments to this post
    fileprivate var attachments : [NSItemProvider] {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return [] }
        return items.flatMap { $0.attachments as? [NSItemProvider] } // remove optional
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
                attachment.fetchURL { url in
                    defer { group.leave() }
                    guard let url = url else { return }
                    queue.async {
                        urls.append(url)
                    }
                }
            }
        }
        group.notify(queue: queue) { _ in callback(urls) }
    }
}

extension NSItemProvider {
    
    /// Extracts the URL from the item provider
    func fetchURL(completion: @escaping (URL?)->()) {
        self.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, urlCompletionHandler: { (url, error) in
            guard let url = url, error == nil else {
                completion(nil)
                return
            }
            completion(url)
        })
    }
    
    /// Extracts data from the item provider
    func fetchData(completion: @escaping(Data?)->()) {
        self.loadItem(forTypeIdentifier: kUTTypeData as String, options: [:], dataCompletionHandler: { (data, error) in
            guard let data = data, error != nil else {
                completion(nil)
                return
            }
            completion(data)
        })
    }
}
