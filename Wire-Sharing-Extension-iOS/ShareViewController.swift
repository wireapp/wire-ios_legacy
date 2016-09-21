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
import ObjectiveC
import WireExtensionComponents
import zshare
import Classy

class ShareViewController: UIViewController, UIScrollViewDelegate, UITextViewDelegate, TokenFieldDelegate, ConversationListViewControllerDelegate {

    
    private lazy var __once: () = {
            ShareViewController.sendingStarted = true
            if let navigationController = ShareViewController.navigationController {
                navigationController.showLoadingView = true
            } else {
                ShareViewController.showLoadingView = true
            }
            ShareViewController.messageTextView.resignFirstResponder()
            ShareViewController.recipientsTokenField.resignFirstResponder()
            ShareViewController.cancelButton.isEnabled = false
            
            var textMessage: TextMessage? = nil
            if let url = ShareViewController.urlToSend {
                textMessage = TextMessage(url: url, message: self.messageToSend)
            } else if let text = ShareViewController.messageToSend {
                textMessage = TextMessage(text: text)
            }
            
            let storeAnalyticsClosure: () -> () = {
                let numberOfGroupRecipients = self.recipientList.reduce(0) { (sum: Int, recipient:Conversation) -> Int in
                    return sum + ((recipient.type == ConversationType.Group) ? 1 : 0)
                }
                
                SharedAnalytics.sharedInstance().tagEvent(AnalyticsEvent.Closed, attributes: [
                    .numberOfImages(self.imagesToSend.count),
                    .hasURL(self.urlToSend != nil),
                    .hasText(self.messageToSend != nil),
                    .numberOfRecipients(self.recipientList.count),
                    .numberOfGroupRecipients(numberOfGroupRecipients),
                    .numberOfOneOnOneRecipients(self.recipientList.count - numberOfGroupRecipients),
                    .cancel("no")
                    ]
                )
            }
            
            let completionClosure: () -> () = {
                DispatchQueue.main.async {
                    ShareViewController.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    ShareViewController.showLoadingView = false
                }
            }
            
            let sendImagesClosure: (_ completion:()->()) -> () = { (completion:@escaping ()->()) in
                if self.imagesToSend.count > 0 {
                    self.shareExtensionAPI.postImages(self.imagesToSend, toConversations: self.recipientList) {
                        (error: NSError?) -> () in
                        completion()
                    }
                } else {
                    completion()
                }
            } as! (() -> ()) -> ()
            
            let sendTextMessageClosure: (_ comletion:()->()) -> () = { (completion:@escaping ()->()) in
                if let message = textMessage {
                    self.shareExtensionAPI.postMessage(message, toConversations: self.recipientList) {
                        (error: NSError?) -> Void in
                        completion()
                    }
                } else {
                    completion()
                }
            } as! (() -> ()) -> ()
            
            sendImagesClosure() {
                sendTextMessageClosure() {
                    storeAnalyticsClosure()
                    completionClosure()
                }
            }
        }()

    
    // MARK: - Outlets
    @IBOutlet fileprivate weak var previewImageContainerView: UIView!
    @IBOutlet fileprivate weak var messageTextView: TextView!
    @IBOutlet fileprivate weak var messageTextBottomConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var messageTextHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var urlLabel: UILabel!
    @IBOutlet fileprivate weak var urlContainerView: UIView!
    @IBOutlet fileprivate weak var URLContainerSeparatorView: UIView!
    @IBOutlet fileprivate weak var urlContainerHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var imageContainerWidth: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var recipientsTokenField : TokenField!
    
    @IBOutlet fileprivate weak var searchingView: UIView!
    @IBOutlet fileprivate weak var messageView: UIScrollView!
    @IBOutlet fileprivate weak var doneButton: IconButton!
    @IBOutlet fileprivate weak var cancelButton: IconButton!
    
    fileprivate var previewImagesController: PreviewImagesViewController! = nil
    fileprivate var conversationListController: ConversationListViewController! = nil
    
    // MARK: - UIViewController overrides
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var barButtonOffset: CGFloat = 0
        if self.traitCollection.userInterfaceIdiom == .pad {
            barButtonOffset = 4
            self.navigationController?.view.layer.cornerRadius = 5
            self.navigationController?.view.clipsToBounds = true
        } else {
            barButtonOffset = 8
        }

        self.doneButton.setIcon(.checkmark, with: .tiny, for: UIControlState())
        self.cancelButton.setIcon(.X, with: .tiny, for: UIControlState())
        
        if let leftItem = self.navigationItem.leftBarButtonItem {
            let leftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
            leftSpacer.width = barButtonOffset
            self.navigationItem.leftBarButtonItems = [leftSpacer, leftItem]
        }
        
        if let rightItem = self.navigationItem.rightBarButtonItem {
            let rightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
            rightSpacer.width = barButtonOffset
            self.navigationItem.rightBarButtonItems = [rightSpacer, rightItem]
        }
        
        self.navigationItem.backBarButtonItem?.title = ""
        
        let image = UIImage(forLogoWith: UIColor.accentColor, iconSize: .medium)
        self.navigationItem.titleView = UIImageView(image: image)
        
        self.recipientsTokenField.accessoryButton.setImage(UIImage(for: .plus, iconSize: .tiny, color: UIColor.black), for: UIControlState())
        self.recipientsTokenField.accessoryButton.cas_styleClass = "dark"
        self.recipientsTokenField.accessoryButton.addTarget(self, action: #selector(ShareViewController.addRecipientPressed(_:)), for: .touchUpInside)
        
        self.recipientsTokenField.toLabelText = NSLocalizedString("sharing-ext.toLabelText", comment:"String for 'To:' label in view with recipients bubles")
        self.messageTextView.placeholder = NSLocalizedString("sharing-ext.message.placeholder", comment:"Placeholder text for user message")

        
        NotificationCenter.default.addObserver(self, selector: #selector(ShareViewController.updateMessageHeight(_:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        
        self.imageContainerWidth.constant = self.previewImagesController.previewImageSize
        
        self.isSearching = false
        
        self.setupUIFromContext(self.extensionContext!)

        let environment: BackendEnvironment
        switch UserDefaults.shared().string(forKey: "ZMBackendEnvironmentType") {
        case .some("staging"): environment = .Staging
        case .some("edge"): environment = .Edge
        default: environment = .Production
        }

        self.shareExtensionAPI = ShareExtensionAPI(backend: Backend(env: environment))

        self.shareExtensionAPI.login { (user: User?, errorOptional: NSError?) -> () in
            if let error = errorOptional {
                let alert = UIAlertController(error: error, context: self.extensionContext!) {
                    self.cancelWithError(error)
                }
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.currentUser = user;
            }
        }
        
        
        SharedAnalytics.sharedInstance().tagEvent(AnalyticsEvent.Opened, attributes:
            [.numberOfImages(self.extensionContext?.imageItemProviders().count ?? 0),
             .hasURL(self.extensionContext?.urlItemProvider() != nil),
             .hasText(self.extensionContext?.plainTextItemProvider() != nil)])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateDoneButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.recipientsTokenField.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.imagesToSend.count > 0) {
            let rect = self.messageTextView.convert(self.previewImageContainerView.frame, from: self.previewImageContainerView.superview)
            let path = UIBezierPath(rect: rect)
            self.messageTextView.textContainer.exclusionPaths = [path]
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass  {
        case .compact:
            self.recipientsTokenField.cas_styleClass = "compact"
            if let navigationBar = self.navigationController?.navigationBar as? FlexibleNavigationBar {
                navigationBar.height = 44                
            }
        case .regular, .unspecified:
            self.recipientsTokenField.cas_styleClass = "regular"
            if let navigationBar = self.navigationController?.navigationBar as? FlexibleNavigationBar {
                navigationBar.height = 60
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Model
    
    fileprivate var shareExtensionAPI: ShareExtensionAPI! = nil {
        didSet {
            if let conversationListController = self.conversationListController {
                conversationListController.shareExtensionAPI = self.shareExtensionAPI
            }
        }
    }
    
    fileprivate var currentUser: User? = nil {
        didSet {
            if let accentColor = self.currentUser?.accentColor {
                UIColor.setAccentColor(accentColor)
                CASStyler.default().applyDefaultColorScheme(withAccentColor: UIColor.accentColor)
                
                let image = UIImage(forLogoWith: UIColor.accentColor, iconSize: .medium)
                self.navigationItem.titleView = UIImageView(image: image)
            
                self.view.cas_setNeedsUpdateStylingForSubviews()
            }
        }
    }
    
    
    // MARK: Data
    
    fileprivate var imagesToSend: Array<ImageMessage> = [] {
        didSet {
            self.updateDoneButton()
        }
    }
    fileprivate var messageToSend: String? = nil {
        didSet {
            self.updateDoneButton()
        }
    }
    fileprivate var urlToSend: URL? = nil {
        didSet {
            self.updateDoneButton()
        }
    }
    
    fileprivate var recipientList = Array<Conversation>()
    
    // MARK: Recipients
    
    // MARK: State
    fileprivate var isSearching: Bool = false {
        didSet {
            self.messageView.isHidden = self.isSearching
            self.searchingView.isHidden = !self.isSearching
        }
    }
    
    var hasContentToSend: Bool {
            return (self.imagesToSend.count > 0) || (self.messageToSend != nil && (self.messageToSend!).characters.count > 0) || (self.urlToSend != nil)
    }
    
    var isReadyToSend: Bool {
        return self.hasContentToSend && (self.recipientList.count > 0)
    }
    
    var sendingStarted: Bool = false
    
    fileprivate func setupUIFromContext(_ context: NSExtensionContext) {
        let imageAttachments = context.imageItemProviders()
        if imageAttachments.count > 0 {
            self.setupViewsForImageAttachmentsWithCount(imageAttachments.count)
            self.loadPreviewImagesForImageAttachments(imageAttachments)
        } else {
            self.hidePreviewImageViews()
        }
        
        let showURLClosure: (Void) -> Void = {
            if let urlAttachment = context.urlItemProvider() {
                urlAttachment.loadURL() { (url: URL) -> Void in
                    self.urlToSend = url
                    self.setupViewsForURL(url)
                }
            } else {
                self.hideURLViews()
            }
        }
        
        if let textAttachment = context.plainTextItemProvider() {
            textAttachment.loadText() { (text: String) -> Void in
                self.messageToSend = text
                self.setupViewsForText(text)
                
                if !text.containsURL() {
                    showURLClosure()
                } else {
                    self.hideURLViews()
                }
            }
        } else {
            showURLClosure()
        }
    }

    
    fileprivate func hideURLViews() {
        self.urlLabel.text = ""
        self.messageTextHeightConstraint.constant += self.urlContainerHeight.constant
        self.urlContainerHeight.isActive = false
        self.URLContainerSeparatorView.isHidden = true
        self.urlContainerView.isHidden = true
    }
    
    fileprivate func hidePreviewImageViews() {
        self.previewImageContainerView.isHidden = true
    }
    
    fileprivate func setupViewsForImageAttachmentsWithCount(_ count:Int) {
        self.previewImagesController.numberOfPreviewImages = count
        
        self.messageTextView.text = ""
        self.messageTextView.superview?.sendSubview(toBack: self.messageTextView)
        self.view.layoutIfNeeded()
    }
    
    fileprivate func setupViewsForURL(_ url: URL) {
        self.messageTextView.text = ""
        self.messageTextView.superview?.sendSubview(toBack: self.messageTextView)
        self.urlLabel.text = url.absoluteString
        
        self.view.layoutIfNeeded()
    }
    
    fileprivate func setupViewsForText(_ text: String) {
        let options = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8 as AnyObject
        ] as [String : AnyObject]
        if let string = try? NSMutableAttributedString(data: text.data(using: String.Encoding.utf8)!, options: options, documentAttributes: nil),
            let font = self.messageTextView.font {
                let attributes = [NSFontAttributeName: font]
                string.setAttributes(attributes, range: NSMakeRange(0, string.length))
                self.messageTextView.attributedText = string
        }
    }
    
    fileprivate func loadPreviewImagesForImageAttachments(_ imageAttachments: Array<NSItemProvider>) {
        for i in 0 ..< imageAttachments.count {
            let attachment = imageAttachments[i]
            let index = i
            let imagePixelSize = self.previewImagesController.previewImageSize * self.traitCollection.displayScale
            
            attachment.loadImage() { (object: NSSecureCoding) -> Void in
                
                if let imageURL = object as? URL {
                    self.imagesToSend.append(ImageMessage(url:imageURL))
                    self.updateDoneButton()
                    
                    UIImage.loadPreviewForImageWithURL(imageURL, maxPixelSize:Int(imagePixelSize)) { (previewImage: UIImage?) -> Void in
                        self.previewImagesController.setImage(previewImage, forPreviewAtIndex: index)
                    }
                } else if let image = object as? UIImage,
                    let imageData = UIImagePNGRepresentation(image) {
                        self.imagesToSend.append(ImageMessage(data: imageData, imageSize: image.size))
                        
                        let previewOptions = [NSItemProviderPreferredImageSizeKey: NSValue(cgSize: CGSize(width: imagePixelSize, height: imagePixelSize))]
                        attachment.loadPreviewImage(options: previewOptions) { (object: NSSecureCoding?, error: NSError!) -> Void in
                            DispatchQueue.main.async {
                                if let previewImage = object as? UIImage {
                                    self.previewImagesController.setImage(previewImage, forPreviewAtIndex: index)
                                } else {
                                    self.previewImagesController.setImage(image, forPreviewAtIndex: index)
                                }
                            }
                        }
                }
            }
        }
    }
    
    fileprivate func updateDoneButton() {
        self.doneButton.isEnabled = self.isReadyToSend  && !self.sendingStarted
    }
    
    func updateMessageHeight(_ note: Notification?) {
        if let frameValue = (note as NSNotification?)?.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let rect = self.view.convert(frameValue.cgRectValue, from: self.view.window)
            let value = self.view.frame.height - rect.minY
            self.messageTextBottomConstraint.constant = (value > 0) ? value : 0
        }
        
        let messageHeight = self.messageTextView.contentSize.height +
            self.messageTextView.textContainerInset.top + self.messageTextView.textContainerInset.bottom
        self.messageTextHeightConstraint.constant = messageHeight
        self.messageTextView.contentOffset = CGPoint.zero
        self.view.layoutIfNeeded()
        
        if (self.messageTextView.isFirstResponder &&
            self.messageView.contentSize.height > self.messageView.frame.height) {
            self.messageView.setContentOffset(CGPoint(x: 0, y: self.messageView.contentSize.height - self.messageView.frame.height), animated: true)
        } else {
            self.messageView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    
    // MARK: - Navigation and Actions

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ConversationListViewController {
            controller.shareExtensionAPI = self.shareExtensionAPI
            controller.delegate = self
            if segue.identifier == "searchForConversations" {
                controller.tableView.cas_styleClass = "embed"
                self.conversationListController = controller
            } else if segue.identifier == "modalSearchForConversations" {
                controller.tableView.cas_styleClass = "pushed"
                controller.excludedConversations = self.recipientList
            }
        } else if let controller = segue.destination as? PreviewImagesViewController {
            if segue.identifier == "embed-preview-images" {
                self.previewImagesController = controller
            }
        }
    }
    
    @IBAction func unwindFromSegue(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func addRecipientPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "modalSearchForConversations", sender: sender)
    }

    @IBAction func cancelPressed(_ sender: AnyObject) {
        self.cancelWithError(NSError(domain: ShareDomain, code: NSUserCancelledError, userInfo: nil))
    }
    
    @IBAction func donePressed(_ sender: AnyObject) {
        self.complete()
        self.updateDoneButton()
    }
    
    func cancelWithError(_ error: NSError) {
        var cancelReason = ""
        if error.code == NSUserCancelledError {
            cancelReason = "userCanceled"
        } else if error.domain == ShareDomain {
            cancelReason = "unauthorized"
        }
        
        SharedAnalytics.sharedInstance().tagEvent(AnalyticsEvent.Closed, attributes: [
            .numberOfImages(self.imagesToSend.count),
            .hasURL(self.urlToSend != nil),
            .hasText(self.messageToSend != nil),
            .numberOfRecipients(self.recipientList.count),
            .cancel(cancelReason),
            ]
        )
        
        self.extensionContext!.cancelRequest(withError: error)
    }
    
    func complete() {
        var dispatchOnceToken: Int = 0
        _ = self.__once
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.messageTextView {
            self.recipientsTokenField.resignFirstResponder()
            if (self.recipientList.count > 1) {
                self.recipientsTokenField.setCollapsed(true, animated: true)
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.messageTextView {
            self.updateMessageHeight(nil)
            self.messageToSend = textView.text
        }
    }

    // MARK: - TokenFieldDelegate
    
    func tokenField(_ tokenField: TokenField!, changedTokensTo tokens: [AnyObject]!) {        
        self.recipientList = tokens.map { (($0 as! Token).representedObject as! Conversation) }
        self.conversationListController.excludedConversations = self.recipientList
        self.updateDoneButton()
    }
    
    func tokenField(_ tokenField: TokenField!, changedFilterTextTo text: String!) {
        self.isSearching = text.characters.count > 0
        self.conversationListController.searchTerm = text
    }
    
    func tokenFieldString(forCollapsedState tokenField: TokenField!) -> String! {
        if (self.recipientList.count > 1) {
            return NSString.localizedStringWithFormat(NSLocalizedString("sharing-ext.recipients-field.collapsed", comment: "Name of first user + number of others more") as NSString,
                self.recipientList[0].displayName, self.recipientList.count-1) as String
        } else if (self.recipientList.count > 0) {
            return self.recipientList[0].displayName
        } else {
            return ""
        }
    }

    // MARK: - ConversationListViewControllerDelegate
    
    func conversationList(_ conversationList: ConversationListViewController, didSelectConversation conversation: Conversation) {
        self.recipientList.append(conversation)
        self.recipientsTokenField.addTokenForTitle(conversation.displayName, representedObject: conversation)
        self.isSearching = false
        
        conversationList.searchTerm = ""
        conversationList.excludedConversations = self.recipientList
        self.conversationListController.searchTerm = ""
        self.conversationListController.excludedConversations = self.recipientList
        
        self.updateDoneButton()
    }
    
}
