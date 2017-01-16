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


var globalSharingSession : SharingSession? = nil

/// The delay after which a progess view controller will be displayed if all messages are not yet sent.
private let progressDisplayDelay: TimeInterval = 0.5


class ShareViewController: SLComposeServiceViewController {
    
    var conversationItem : SLComposeSheetConfigurationItem?
    var selectedConversation : Conversation?

    private var observer: SendableBatchObserver? = nil
    private weak var progressViewController: SendingProgressViewController? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationBar()
        self.appendTextToEditor()
        self.placeholder = "share_extension.input.placeholder".localized
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    private func setupNavigationBar() {
        guard let item = navigationController?.navigationBar.items?.first else { return }
        item.rightBarButtonItem?.action = #selector(appendPostTapped)
        item.rightBarButtonItem?.title = "share_extension.send_button.title".localized
        item.titleView = UIImageView(image: UIImage(forLogoWith: .black, iconSize: .small))
    }

    deinit {
        observer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.view.backgroundColor = .white
    }
    
    override func presentationAnimationDidFinish() {
        let bundle = Bundle.main
        
        if let applicationGroupIdentifier = bundle.infoDictionary?["ApplicationGroupIdentifier"] as? String,
            let hostBundleIdentifier = bundle.infoDictionary?["HostBundleIdentifier"] as? String,
            globalSharingSession == nil {
                globalSharingSession = try? SharingSession(applicationGroupIdentifier: applicationGroupIdentifier, hostBundleIdentifier: hostBundleIdentifier)
            }
    
        guard let sharingSession = globalSharingSession, sharingSession.canShare else {
            presentNotSignedInMessage()
            return
        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return globalSharingSession != nil && selectedConversation != nil
    }

    /// invoked when the user wants to post
    func appendPostTapped() {

        send { [weak self] (messages) in
            guard let `self` = self else { return }
            self.observer = SendableBatchObserver(sendables: messages)
            self.observer?.progressHandler = {
                self.progressViewController?.progress = $0
            }

            self.navigationController?.navigationBar.items?.first?.rightBarButtonItem?.isEnabled = false
            
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
        if let parentView = super.loadPreviewView() {
            return parentView
        }
        let hasURL = self.attachments.first(where: { $0.hasItemConformingToTypeIdentifier(kUTTypeURL as String) }) != nil
        let hasEmptyText = self.textView.text.isEmpty
        // I can not ask if it's a http:// or file://, because it's an async operation, so I rely on the fact that 
        // if it has no image, it has a URL and it has text, it must be a file
        if  hasURL && hasEmptyText {
            return UIImageView(image: UIImage(for: .document, iconSize: .large, color: UIColor.black))
        }
        return nil
    }

    /// If there is a URL attachment, copy the text of the URL attachment into the text field
    private func appendTextToEditor() {
        self.fetchURLAttachments { (urls) in
            guard let url = urls.first else { return }
            DispatchQueue.main.async {
                if !url.isFileURL { // remote URL (not local file)
                    let separator = self.textView.text.isEmpty ? "" : "\n"
                    self.textView.text = self.textView.text + separator + url.absoluteString
                    self.textView.delegate?.textViewDidChange?(self.textView)
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

            globalSharingSession?.enqueue {
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
        guard let sharingSession = globalSharingSession else { return }

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
            let sharingSession = globalSharingSession else {
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
        
        self.attachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                sendingGroup.enter()
                self.sendAsImage(sharingSession: sharingSession, conversation: conversation, attachment: attachment, completionHandler: completeAndAppendToMessages)
            }
            else if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                sendingGroup.enter()
                attachment.fetchURL { url in
                    if let url = url, !url.isFileURL == true { // remote URL, send as link
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
            
            if !text.isEmpty {
                sendingGroup.enter()
                self.sendAsText(sharingSession: sharingSession, conversation: conversation, text: text, completionHandler: completeAndAppendToMessages)
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
            
            self.prepareForSending(data:data, UTIString: UTIString, name: name) { url, error in
                
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
        attachment.loadItem(forTypeIdentifier: kUTTypeImage as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], imageCompletionHandler: { (image, error) in
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
    private func prepareForSending(data: Data, UTIString UTI: String, name: String?, completionHandler: @escaping (URL?, Error?) -> Void) {
        guard let fileName = nameForFile(withUTI: UTI, name: name) else {
            return completionHandler(nil, nil)
        }
        
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString) // temp subdir
        if !FileManager.default.fileExists(atPath: tempDirectory.absoluteString) {
            try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }
        let tempFileURL = tempDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: tempFileURL.absoluteString) {
            try! FileManager.default.removeItem(at: tempFileURL)
        }
        do {
            try data.write(to: tempFileURL)
        } catch {
            completionHandler(nil, error)
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

    private func nameForFile(withUTI UTI: String, name: String?) -> String? {
        if let fileExtension = UTTypeCopyPreferredTagWithClass(UTI as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() as? String {
            return "\(UUID().uuidString).\(fileExtension)"
        }
        return name
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
