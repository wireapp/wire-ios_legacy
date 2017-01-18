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
    var postContent : PostContent?

    private var observer: SendableBatchObserver? = nil
    private weak var progressViewController: SendingProgressViewController? = nil
    private var conversationDegradationObserverToken : Any? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationBar()
        self.appendTextToEditor()
        self.placeholder = "share_extension.input.placeholder".localized
        self.postContent = PostContent(attachments: self.allAttachments)
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
        self.removeConversationObserver()
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
        return globalSharingSession != nil && self.postContent?.target != nil
    }

    /// invoked when the user wants to post
    func appendPostTapped() {

        var sendingCompleted = false
        
        let didScheduleSending : (Void)->Void = { [weak self] _ in
            self?.navigationController?.navigationBar.items?.first?.rightBarButtonItem?.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                guard !sendingCompleted else { return }
                self?.presentSendingProgress()
            }
        }
        let newProgressAvailable : (Float)->Void = { [weak self] progress in
            self?.progressViewController?.progress = progress
        }
        let didFinishSending : (Void)->Void = { [weak self] _ in
            sendingCompleted = true
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
        let conversationDidDegrade : (Set<ZMUser>, @escaping PostContent.DegradationStrategyChoice)->Void = { [weak self] users, strategyChoice in
            guard let `self` = self else { return }
            self.conversationDidDegrade(change: ConversationDegradationInfo(conversation: self.postContent!.target!, users: users), callback: strategyChoice)
        }
        
        self.postContent?.send(text: self.textView.text,
                               didScheduleSending: didScheduleSending,
                               newProgressAvailable: newProgressAvailable,
                               didFinishSending: didFinishSending,
                               conversationDidDegrade: conversationDidDegrade
                               )
    }
    
    
    /// Display a preview image
    override func loadPreviewView() -> UIView! {
        if let parentView = super.loadPreviewView() {
            return parentView
        }
        let hasURL = self.allAttachments.first(where: { $0.hasItemConformingToTypeIdentifier(kUTTypeURL as String) }) != nil
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
        self.postContent?.fetchURLAttachments { (urls) in
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
    
    /// Unregister conversation observer
    private func removeConversationObserver() {
        self.conversationDegradationObserverToken = nil
    }
    
    private func presentChooseConversation() {
        guard let sharingSession = globalSharingSession else { return }

        let allConversations = sharingSession.writeableNonArchivedConversations + sharingSession.writebleArchivedConversations
        let conversationSelectionViewController = ConversationSelectionViewController(conversations: allConversations)
        
        conversationSelectionViewController.selectionHandler = { [weak self] conversation in            
            self?.conversationItem?.value = conversation.name
            self?.postContent?.target = conversation
            self?.popConfigurationViewController()
            self?.validateContent()
        }
        
        pushConfigurationViewController(conversationSelectionViewController)
    }
    
    private func conversationDidDegrade(change: ConversationDegradationInfo, callback: @escaping PostContent.DegradationStrategyChoice) {
        let title = titleForMissingClients(users: change.users)
        let alert = UIAlertController(title: title, message: "meta.degraded.dialog_message".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "meta.degraded.send_anyway_button".localized, style: .destructive, handler: { _ in
            callback(.sendAnyway)
        }))
        alert.addAction(UIAlertAction(title: "meta.degraded.cancel_sending_button".localized, style: .cancel, handler: { _ in
            callback(.cancelSending)
        }))
        self.present(alert, animated: true)
    }
    
    /// Get all the attachments to this post
    var allAttachments : [NSItemProvider] {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return [] }
        return items.flatMap { $0.attachments as? [NSItemProvider] } // remove optional
            .flatMap { $0 } // flattens array
    }
}

private func titleForMissingClients(users: Set<ZMUser>) -> String {
    let template = users.count > 1 ? "meta.degraded.degradation_reason_message.plural" : "meta.degraded.degradation_reason_message.singular"
    let allUsers = (users.map { $0.displayName ?? "" } as NSArray).componentsJoined(by: ", ") as NSString
    return NSString(format: template.localized as NSString, allUsers) as String
}
