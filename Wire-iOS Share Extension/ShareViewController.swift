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

class ShareViewController: SLComposeServiceViewController {
    
    var conversationItem : SLComposeSheetConfigurationItem?
    var sharingSession : SharingSession?
    var selectedConversation : Conversation?
    var label = UILabel()
    
    override func presentationAnimationDidFinish() {
        let bundle = Bundle.main
        
        if let applicationGroupIdentifier = bundle.infoDictionary?["ApplicationGroupIdentifier"] as? String, let hostBundleIdentifier = bundle.infoDictionary?["HostBundleIdentifier"] as? String {
            sharingSession = try? SharingSession(applicationGroupIdentifier: applicationGroupIdentifier, hostBundleIdentifier: hostBundleIdentifier)
        }
        
        guard let sharingSession = sharingSession, sharingSession.canShare else {
            presentNotSignedInMessage()
            return
        }
        
//        extensionContext?.inputItems.forEach { inputItem in
//            if let extensionItem = inputItem as? NSExtensionItem, let attachments = extensionItem.attachments as? [NSItemProvider] {
//                for attachment in attachments {
//                    
//                    guard attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) else { continue }
//                    
//                    let preferredSize = NSValue.init(cgSize: CGSize(width: 1024, height: 1024))
//                    
//                    attachment.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], imageCompletionHandler: { (image, error) in
//                        print(image)
//                    })
//                }
//            }
//        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return sharingSession != nil && selectedConversation != nil
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        
//        extensionContext?.inputItems.forEach { inputItem in
//            if let extensionItem = inputItem as? NSExtensionItem, let attachments = extensionItem.attachments as? [NSItemProvider] {
//                for inputItem in attachments {
//                    inputItem.loadItem(forTypeIdentifier: kUTTypeJPEG as String,
//                                       options: [NSItemProviderPreferredImageSizeKey : CGSize(width: 1024, height: 1024)],
//                                       completionHandler: { (object: NSSecureCoding?, error: Error!) in
////                        print(item)
//                                        print("apa")
//                        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//                    })
//                }
//            }
//        }
        
    
        if let sharingSession = sharingSession, let conversation = selectedConversation {
            sharingSession.enqueue(changes: { 
                _ = conversation.appendTextMessage(self.contentText)
            })
        }
        
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    
    func sendImages() {
        guard selectedConversation != nil else { return }
        
        
        extensionContext?.inputItems.forEach { inputItem in
            if let extensionItem = inputItem as? NSExtensionItem, let attachments = extensionItem.attachments as? [NSItemProvider] {
                for attachment in attachments {
                    
                    guard attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) else { continue }
                    
                    let preferredSize = NSValue.init(cgSize: CGSize(width: 1024, height: 1024))
                    
                    attachment.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: [NSItemProviderPreferredImageSizeKey : preferredSize], dataCompletionHandler: { [weak self] (data, error) in
                        
                        guard let data = data, error == nil else {
                            self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            if let sharingSession = self?.sharingSession, let conversation = self?.selectedConversation {
                                sharingSession.enqueue(changes: {
                                    _ = conversation.appendImage(data)
                                })
                            }
                            
//                            self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                        }
                        })
                }
            }
        }
    }

    override func configurationItems() -> [Any]! {
        let conversationItem = SLComposeSheetConfigurationItem()!
        self.conversationItem = conversationItem
        
        conversationItem.title = NSString(string: "Share to:") as String
        conversationItem.value = NSString(string: "None") as String
        conversationItem.tapHandler = { [weak self] in
             self?.selectConversation()
        }
        
        return [conversationItem]
    }
    
    func presentNotSignedInMessage() {
        let notSignedInViewController = NotSignedInViewController()
        
        notSignedInViewController.closeHandler = { [weak self] in
            self?.cancel()
        }
        
        pushConfigurationViewController(notSignedInViewController)
    }
    
    func selectConversation() {
        guard let sharingSession = sharingSession else { return }

        let conversationSelectionViewController = ConversationSelectionViewController(conversations: sharingSession.writeableNonArchivedConversations)
        
        conversationSelectionViewController.selectionHandler = { [weak self] conversation in
            self?.conversationItem?.value = conversation.name
            self?.selectedConversation = conversation
            self?.popConfigurationViewController()
            self?.validateContent()
            
            self?.sendImages()
        }
        
        pushConfigurationViewController(conversationSelectionViewController)
    }
    
}

class NotSignedInViewController : UIViewController {
    
    var closeHandler : (() -> Void)?
    
    let messageLabel = UILabel()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))
        
        messageLabel.text = "You need to sign into Wire before you can share anything";
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        view.addSubview(messageLabel)
        
        constrain(view, messageLabel) { container, messageLabel in
            messageLabel.edges == container.edgesWithinMargins
        }
    }
    
    func close() {
        if let closeHandler = closeHandler {
            closeHandler()
        }
    }
}

class ConversationSelectionViewController : UITableViewController {
    
    var conversations : [Conversation]
    
    var selectionHandler : ((_ conversation: Conversation) -> Void)?
    
    init(conversations: [Conversation]) {
        self.conversations = conversations
        
        super.init(style: .plain)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ConversationCell")
        preferredContentSize = UIScreen.main.bounds.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath)
        
        cell.textLabel?.text = conversation.name
        cell.backgroundColor = .clear
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectionHandler =  selectionHandler {
            selectionHandler(conversations[indexPath.row])
        }
    }
    
}
