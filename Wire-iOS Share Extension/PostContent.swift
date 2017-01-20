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
import UIKit
import WireExtensionComponents
import WireShareEngine
import MobileCoreServices


/// Content that is shared on a share extension post attempt
class PostContent {
    
    var conversationObserverToken : Any?
    
    /// Conversation to post to
    var target : Conversation? = nil
    
    /// Whether the posting was canceled
    var isCanceled : Bool = false

    fileprivate var batchObserver : SendableBatchObserver?
    
    /// List of attachments to post
    var attachments : [NSItemProvider]
    
    init(attachments: [NSItemProvider]) {
        self.attachments = attachments
    }
}

// MARK: - Send attachments

/// What to do when a conversation that was verified degraded (we discovered a new
/// non-verified client)
enum DegradationStrategy {
    case sendAnyway
    case cancelSending
}

extension PostContent {
    
    typealias DegradationStrategyChoice = (DegradationStrategy)->()
    
    /// Send the content to the selected conversation
    func send(text: String,
              sharingSession: SharingSession,
              didScheduleSending: @escaping () -> Void,
              newProgressAvailable: @escaping (Float) -> Void,
              didFinishSending: @escaping (Void) -> Void,
              conversationDidDegrade: @escaping (Set<ZMUser>, @escaping DegradationStrategyChoice) -> Void
        ) {
        
        let conversation = self.target!
        
        let allMessagesEnqueuedGroup = DispatchGroup()
        allMessagesEnqueuedGroup.enter()
        
        let conversationObserverToken = conversation.add(conversationVerificationDegradedObserver: { [weak self]
            change in
            // make sure that we notify only when we are done preparing all the ones to be sent
            allMessagesEnqueuedGroup.notify(queue: DispatchQueue.main, execute: { 
                conversationDidDegrade(change.users) {
                    switch $0 {
                    case .sendAnyway:
                        conversation.resendMessagesThatCausedConversationSecurityDegradation()
                    case .cancelSending:
                        conversation.doNotResendMessagesThatCausedDegradation()
                        self?.batchObserver = nil
                        didFinishSending()
                    }
                }
            })
        })
        
        self.sendAttachments(sharingSession: sharingSession,
                             conversation: conversation,
                             text: text)
        { [weak self]
            messages in
            allMessagesEnqueuedGroup.leave()

            self?.batchObserver = SendableBatchObserver(sendables: messages)
            self?.batchObserver?.progressHandler = {
                newProgressAvailable($0)
            }
            
            didScheduleSending()
            
            self?.batchObserver?.sentHandler = {
                conversationObserverToken.tearDown()
                didFinishSending()
                self?.batchObserver = nil
            }
        }
    }
    
    /// Send all attachments
    fileprivate func sendAttachments(sharingSession: SharingSession,
                                     conversation: Conversation,
                                     text: String,
                                     didScheduleSending: @escaping ([Sendable])->()) {
        
        let sendingGroup = DispatchGroup()
        
        var messages : [Sendable] = [] // this will always modifed on the main thread
        
        let completeAndAppendToMessages : (Sendable?)->() = { [weak self] sendable in
            defer { sendingGroup.leave() }
            guard let sendable = sendable else {
                return
            }
            messages.append(sendable)
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
                didScheduleSending(messages)
            }
        }
    }
    
    /// Appends a file message, and invokes the callback when the message is available
    fileprivate func sendAsFile(sharingSession: SharingSession, conversation: Conversation, name: String?, attachment: NSItemProvider, completionHandler: @escaping (Sendable?)->()) {
        
        attachment.loadItem(forTypeIdentifier: kUTTypeData as String, options: [:], dataCompletionHandler: { (data, error) in
            
            guard let data = data, let UTIString = attachment.registeredTypeIdentifiers.first as? String, error == nil else {
                sharingSession.enqueue {
                    completionHandler(nil)
                }
                return
            }
            
            self.prepareForSending(data:data, UTIString: UTIString, name: name) { url, error in
                
                guard let url = url, error == nil else {
                    sharingSession.enqueue {
                        completionHandler(nil)
                    }
                    return
                }
                
                FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI(), name: name ?? url.lastPathComponent) { metadata -> Void in
                    sharingSession.enqueue {
                        completionHandler(conversation.appendFile(metadata))
                    }
                }
            }
        })
    }

    /// Appends an image message, and invokes the callback when the message is available
    fileprivate func sendAsImage(sharingSession: SharingSession, conversation: Conversation, attachment: NSItemProvider, completionHandler: @escaping (Sendable?)->()) {
        let preferredSize = NSValue.init(cgSize: CGSize(width: 1024, height: 1024))
        attachment.loadItem(forTypeIdentifier: kUTTypeImage as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], imageCompletionHandler: { (image, error) in

            sharingSession.enqueue {
                guard let image = image, let imageData = UIImageJPEGRepresentation(image, 0.9), error == nil else {
                    completionHandler(nil)
                    return
                }
                
                completionHandler(conversation.appendImage(imageData))
            }
        })
    }
    
    /// Appends an image message, and invokes the callback when the message is available
    fileprivate func sendAsText(sharingSession: SharingSession, conversation: Conversation, text: String, completionHandler: @escaping (Sendable?)->()) {
        sharingSession.enqueue {
            completionHandler(conversation.appendTextMessage(text))
        }
    }
    
    /// Process data to the right format to be sent
    private func prepareForSending(data: Data, UTIString UTI: String, name: String?, completionHandler: @escaping (URL?, Error?) -> Void) {
        let fileExtension = UTTypeCopyPreferredTagWithClass(UTI as CFString, kUTTagClassFilenameExtension as CFString)?.takeRetainedValue() as! String
        
        let fileName = name ?? "\(UUID().uuidString).\(fileExtension)"
        
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
            AVAsset.wr_convertVideo(at: tempFileURL) { [weak self] (url, _, error) in
                // Video conversation can take a while, we need to ensure the user did not cancel
                if self?.isCanceled == false {
                    completionHandler(url, error)
                } else {
                    completionHandler(nil, error)
                }
            }
        } else {
            completionHandler(tempFileURL, nil)
        }
    }
}

// MARK: - Process attachements
extension PostContent {
    
    /// Gets all the URLs in this post, and invoke the callback (on main queue) when done
    func fetchURLAttachments(callback: @escaping ([URL])->()) {
        var urls : [URL] = []
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "share extension URLs queue")
        
        self.attachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                group.enter()
                attachment.fetchURL { url in
                    queue.async {
                        defer {  group.leave() }
                        guard let url = url else { return }
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
