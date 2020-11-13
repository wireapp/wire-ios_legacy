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
import MobileCoreServices
import WireDataModel
import WireCommonComponents
import WireLinkPreview

private let zmLog = ZMSLog(tag: "UI")

/// The delay after which a progess view controller will be displayed if all messages are not yet sent.
private let progressDisplayDelay: TimeInterval = 0.5

private enum LocalAuthenticationStatus {
    case disabled
    case denied
    case granted
}

final class ShareExtensionViewController: SLComposeServiceViewController {

    // MARK: - Elements

    lazy var accountItem : SLComposeSheetConfigurationItem = { [weak self] in
        let item = SLComposeSheetConfigurationItem()!
        let accountName = self?.currentAccount?.shareExtensionDisplayName
        
        item.title = "share_extension.conversation_selection.account".localized
        item.value = accountName ?? "share_extension.conversation_selection.empty.value".localized
        item.tapHandler = { [weak self] in
            self?.presentChooseAccount()
        }
        return item
    }()
    
    lazy var conversationItem : SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        
        item.title = "share_extension.conversation_selection.title".localized
        item.value = "share_extension.conversation_selection.empty.value".localized
        item.tapHandler = { [weak self] in
            self?.presentChooseConversation()
        }
        return item
    }()

    lazy var preview: PreviewImageView? = {
        let imageView = PreviewImageView(frame: .zero)
        imageView.clipsToBounds = true
        imageView.shouldGroupAccessibilityChildren = true
        imageView.isAccessibilityElement = false
        return imageView
    }()

    fileprivate var postContent: PostContent?
    fileprivate var sharingSession: SharingSession? = nil
    
    /// stores extensionContext?.attachments
    fileprivate var attachments: [AttachmentType: [NSItemProvider]] = [:]
    
    fileprivate var currentAccount: Account? = nil
    fileprivate var localAuthenticationStatus: LocalAuthenticationStatus = .disabled
    private var observer: SendableBatchObserver? = nil
    private weak var progressViewController: SendingProgressViewController? = nil

    // MARK: - Host App State

    private var accountManager: AccountManager? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        return AccountManager(sharedDirectory: sharedContainerURL)
    }

    // MARK: - Configuration

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupObserver()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupObserver()
    }

    deinit {
        StorageStack.reset()
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(extensionHostDidEnterBackground), name: .NSExtensionHostDidEnterBackground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentAccount = accountManager?.selectedAccount
        ExtensionBackupExcluder.exclude()
        CrashReporter.setupAppCenterIfNeeded()
        updateAccount(currentAccount)
        
        if let sortedAttachments = extensionContext?.attachments.sorted {
            attachments = sortedAttachments
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.postContent = PostContent(attachments: extensionContext?.attachments ?? [])
        self.setupNavigationBar()
        self.appendTextToEditor()
        appendFileTextToEditor()
        self.updatePreview()
        self.placeholder = "share_extension.input.placeholder".localized
    }

    private func setupNavigationBar() {
        let iconSize = CGSize(width: 32, height: 26.3)
        guard let item = navigationController?.navigationBar.items?.first else { return }
        item.rightBarButtonItem?.action = #selector(appendPostTapped)
        item.rightBarButtonItem?.title = "share_extension.send_button.title".localized
        item.titleView = UIImageView(image: WireStyleKit.imageOfLogo(color: UIColor.Wire.primaryLabel).downscaling(to: iconSize))
    }

    private var authenticatedAccounts: [Account] {
        guard let accountManager = accountManager else { return [] }
        return accountManager.accounts.filter { BackendEnvironment.shared.isAuthenticated($0) }
    }
    
    private func recreateSharingSession(account: Account?) throws {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier,
            let hostBundleIdentifier = Bundle.main.hostBundleIdentifier,
            let accountIdentifier = account?.userIdentifier
            else { return }

        sharingSession = try SharingSession(
            applicationGroupIdentifier: applicationGroupIdentifier,
            accountIdentifier: accountIdentifier,
            hostBundleIdentifier: hostBundleIdentifier,
            environment: BackendEnvironment.shared
        )
    }

    override func configurationItems() -> [Any]! {
        if accountManager?.accounts.count > 1 {
            return [accountItem, conversationItem]
        } else {
            return [conversationItem]
        }
    }

    // MARK: - Events

    @objc private func extensionHostDidEnterBackground() {
        postContent?.cancel { [weak self] in
            self?.cancel()
        }
    }

    override func presentationAnimationDidFinish() {
        if authenticatedAccounts.count == 0 {
            return presentNotSignedInMessage()
        }
    }

    // MARK: - Editing

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        let textLength = self.contentText.trimmingCharacters(in: .whitespaces).count
        let remaining = SharedConstants.maximumMessageLength - textLength
        let remainingCharactersThreshold = 30
        
        if remaining <= remainingCharactersThreshold {
            self.charactersRemaining = remaining as NSNumber
        } else {
            self.charactersRemaining = nil
        }
        
        let conditions = sharingSession != nil && self.postContent?.target != nil
        return self.charactersRemaining == nil ? conditions : conditions && self.charactersRemaining.intValue >= 0
    }

    /// If there is a URL attachment, copy the text of the URL attachment into the text field
    private func appendTextToEditor() {
        guard let urlItems = attachments[.url] else {
            return
        }

        urlItems.first?.fetchURL { url in
            DispatchQueue.main.async {
                guard let url = url, !url.isFileURL else { return }
                let separator = self.textView.text.isEmpty ? "" : "\n"
                self.textView.text = self.textView.text + separator + url.absoluteString
                self.textView.delegate?.textViewDidChange?(self.textView)
            }
        }
    }


    /// If there is a File URL attachment, copy the filename of the URL attachment into the text field
    private func appendFileTextToEditor() {
        guard let urlItems = attachments[.fileUrl] else {
            return
        }

        urlItems.first?.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil, completionHandler: { (url, error) in
            error?.log(message: "Unable to fetch URL for type URL")
            guard let url = url as? URL, url.isFileURL else { return }

            let filename = url.lastPathComponent
            let separator = self.textView.text.isEmpty ? "" : "\n"

            DispatchQueue.main.async {
                self.textView.text = self.textView.text + separator + filename
                self.textView.delegate?.textViewDidChange?(self.textView)
            }

        })
    }

    /// Invoked when the user wants to post.
    @objc
    private func appendPostTapped() {
        guard let sharingSession = sharingSession else { return }

        navigationController?.navigationBar.items?.first?.rightBarButtonItem?.isEnabled = false
        
        postContent?.send(text: contentText, sharingSession: sharingSession) { [weak self] progress in
            guard let `self` = self, let postContent = self.postContent else { return }

            switch progress {
            case .preparing:
                DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                    guard !postContent.sentAllSendables && nil == self.progressViewController else { return }
                    self.presentSendingProgress(mode: .preparing)
                }

            case .startingSending:
                DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                    guard postContent.sentAllSendables && nil == self.progressViewController else { return }
                    self.presentSendingProgress(mode: .sending)
                }

            case .sending(let progress):
                self.progressViewController?.progress = progress

            case .done:
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                    self.view.alpha = 0
                    self.navigationController?.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }, completion: { _ in
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })

            case .conversationDidDegrade((let users, let strategyChoice)):
                if let conversation = postContent.target {
                    self.conversationDidDegrade(
                        change: ConversationDegradationInfo(conversation: conversation, users: users),
                        callback: strategyChoice)
                }
            case .timedOut:
                self.popConfigurationViewController()
                
                let alert = UIAlertController.alertWithOKButton(title: "share_extension.timeout.title".localized, message: "share_extension.timeout.message".localized)
                
                self.present(alert, animated: true)
                
            case .error(let error):
                if let errorDescription = (error as? UnsentSendableError )?.errorDescription {
                    let alert = UIAlertController.alertWithOKButton(title: nil, message: errorDescription)
                    
                    self.present(alert, animated: true) {
                        self.popConfigurationViewController()
                    }
                }
            }
        }
    }

    // MARK: - Preview
    
    /// Display a preview image.
    override func loadPreviewView() -> UIView! {
        return preview
    }


    func updatePreview() {
        fetchMainAttachmentPreview { previewItem, displayMode in
            DispatchQueue.main.async {
                guard let previewItem = previewItem else {
                    self.preview?.image = nil
                    self.preview?.isHidden = true
                    return
                }

                switch previewItem {
                case .image(let image):
                    self.preview?.image = image
                    self.preview?.displayMode = displayMode
                case .placeholder(let iconType):
                    self.preview?.setIcon(iconType, size: .medium, color: UIColor.Wire.secondaryLabel)

                case .remoteURL(let url):
                    self.preview?.setIcon(.browser, size: .medium, color: UIColor.Wire.secondaryLabel)
                    self.fetchWebsitePreview(for: url)
                }

                self.preview?.displayMode = displayMode
                self.preview?.isHidden = false
            }
        }
    }

    /// Fetches the preview image for the given website.
    private func fetchWebsitePreview(for url: URL) {
        sharingSession?.downloadLinkPreviews(inText: url.absoluteString, excluding: []) { previews in
            let previewImage: UIImage?

            /// size the image to fill the image view
            if let imageData = previews.first?.imageData.first,
               let image = UIImage(data: imageData),
               let requiredSize = self.preview?.frame.size.shortestLength {
                previewImage = image.downsized(shorterSizeLength: requiredSize)
            } else {
                previewImage = nil
            }

            DispatchQueue.main.async {
                self.preview?.displayMode = .link
                self.preview?.image = previewImage
            }
        }
    }

    // MARK: - Transitions

    private func presentSendingProgress(mode: SendingProgressViewController.ProgressMode) {
        let progressSendingViewController = SendingProgressViewController()
        progressViewController?.mode = mode

        progressSendingViewController.cancelHandler = { [weak self] in
            self?.postContent?.cancel {
                self?.cancel()
            }
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
    
    func updateState(conversation: Conversation?) {
        conversationItem.value = conversation?.name ?? "share_extension.conversation_selection.empty.value".localized
        postContent?.target = conversation
    }
    
    func updateAccount(_ account: Account?) {

        var account = account
        let authenticated = authenticatedAccounts
        
        // If the current account is not authenticated (e.g. device removed from another client)
        // and there are other accounts authenticated, it switches to the first available.
        
        let accountAuthenticated = account.flatMap(BackendEnvironment.shared.isAuthenticated) ?? false
        
        if let firstLogged = authenticated.first, account == currentAccount, accountAuthenticated == false {
            account = firstLogged
        }
        
        do {
            try recreateSharingSession(account: account)
        } catch let error as SharingSession.InitializationError {
            guard error == .loggedOut else { return }
            
            let alert = UIAlertController.alertWithOKButton(title: "share_extension.logged_out.title".localized, message: "share_extension.logged_out.message".localized)

            self.present(alert, animated: true)
            return
        } catch { //any other error
            return
        }
        
        currentAccount = account
        accountItem.value = account?.shareExtensionDisplayName ?? ""
        conversationItem.value = "share_extension.conversation_selection.empty.value".localized
        
        guard account != currentAccount else { return }
        postContent?.target = nil
    }
    
    private func presentChooseAccount() {
        requireLocalAuthenticationIfNeeded(with: { [weak self] (status) in
            if let status = status, status != .denied {
                self?.showChooseAccount()
            }
        })
    }
    
    private func presentChooseConversation() {
        requireLocalAuthenticationIfNeeded(with: { [weak self] (status) in
            if let status = status, status != .denied {
                self?.showChooseConversation()
            }
        })
    }
    
    func showChooseConversation() {
        
        guard let sharingSession = sharingSession else { return }
        
        let allConversations = sharingSession.writeableNonArchivedConversations + sharingSession.writebleArchivedConversations
        let conversationSelectionViewController = ConversationSelectionViewController(conversations: allConversations)
        
        conversationSelectionViewController.selectionHandler = { [weak self] conversation in
            self?.updateState(conversation: conversation)
            self?.popConfigurationViewController()
            self?.validateContent()
        }
        
        pushConfigurationViewController(conversationSelectionViewController)
    }
    
    func showChooseAccount() {
        
        guard let accountManager = accountManager else { return }
        let accountSelectionViewController = AccountSelectionViewController(accounts: accountManager.accounts,
                                                                            current: currentAccount)
        
        accountSelectionViewController.selectionHandler = { [weak self] account in
            self?.updateAccount(account)
            self?.popConfigurationViewController()
            self?.validateContent()
        }
        
        pushConfigurationViewController(accountSelectionViewController)
    }

    /// @param callback confirmation; called when authentication evaluation is completed.
    fileprivate func requireLocalAuthenticationIfNeeded(with callback: @escaping (LocalAuthenticationStatus?)->()) {
        
        // I need to store the current authentication in order to avoid future authentication requests in the same Share Extension session
        
        guard
            let sharingSession = sharingSession,
            AppLock.isActive || sharingSession.encryptMessagesAtRest
        else {
            localAuthenticationStatus = .disabled
            callback(localAuthenticationStatus)
            return
        }
        
        guard localAuthenticationStatus != .granted, sharingSession.isDatabaseLocked else {
            callback(localAuthenticationStatus)
            return
        }
        
        let scenario: AppLock.AuthenticationScenario
        
        if sharingSession.encryptMessagesAtRest {
            scenario = .databaseLock
        } else {
            scenario = .screenLock(requireBiometrics: AppLock.rules.useBiometricsOrAccountPassword,
                                   grantAccessIfPolicyCannotBeEvaluated: !AppLock.rules.forceAppLock)
        }
        
        AppLock.evaluateAuthentication(scenario: scenario,
                                       description: "share_extension.privacy_security.lock_app.description".localized)
        { [weak self] (result, context) in
            DispatchQueue.main.async {
                if case .granted = result {
                    self?.localAuthenticationStatus = .granted
                    try? self?.sharingSession?.unlockDatabase(with: context)
                } else {
                    self?.localAuthenticationStatus = .denied
                }
                callback(self?.localAuthenticationStatus)
            }
        }
    }
    
    
    private func conversationDidDegrade(change: ConversationDegradationInfo, callback: @escaping DegradationStrategyChoice) {
        let title = titleForMissingClients(causedBy: change)
        let alert = UIAlertController(title: title, message: "meta.degraded.dialog_message".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "meta.degraded.send_anyway_button".localized, style: .destructive, handler: { _ in
            callback(.sendAnyway)
        }))
        alert.addAction(UIAlertAction(title: "meta.degraded.cancel_sending_button".localized, style: .cancel, handler: { _ in
            callback(.cancelSending)
        }))
        self.present(alert, animated: true)
    }

    private func titleForMissingClients(causedBy change: ConversationDegradationInfo) -> String {
        if change.conversation.legalHoldStatus == .pendingApproval {
            return "meta.legalhold.send_alert_title".localized
        }

        let users = change.users
        let template = users.count > 1 ? "meta.degraded.degradation_reason_message.plural" : "meta.degraded.degradation_reason_message.singular"
    
        let allUsers = (users.compactMap(\.name) as NSArray).componentsJoined(by: ", ") as NSString
        return String.localizedStringWithFormat(template.localized, allUsers)
    }

}
