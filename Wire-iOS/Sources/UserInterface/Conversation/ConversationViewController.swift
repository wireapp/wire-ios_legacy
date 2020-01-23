//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireDataModel

final class ConversationViewController: UIViewController {
    weak var zClientViewController: ZClientViewController?
    var conversation: ZMConversation! { ///TODO: change to optional
        didSet {
            if oldValue == conversation {
                return
            }

            setupNavigatiomItem()
            updateOutgoingConnectionVisibility()
            
            if let conversation = conversation {
                voiceChannelStateObserverToken = addCallStateObserver()
                conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
                startCallController = ConversationCallController(conversation: conversation, target: self)
            }
        }
    }

    weak var session: ZMUserSessionInterface?
    weak var visibleMessage: ZMConversationMessage?
    var isFocused = false
    
    ///TODO: create when init
    private(set) var startCallController: ConversationCallController!
    
    private(set) var contentViewController: ConversationContentViewController!
    private(set) var inputBarController: ConversationInputBarViewController!

    var collectionController: CollectionsViewController?
    var outgoingConnectionViewController: OutgoingConnectionViewController!
    private(set) var conversationBarController: BarController!
    private(set) var guestsBarController: GuestsBarController!
    private(set) var invisibleInputAccessoryView: InvisibleInputAccessoryView!
    var inputBarBottomMargin: NSLayoutConstraint?
    var inputBarZeroHeight: NSLayoutConstraint?
    
    var isAppearing = false
    var mediaBarViewController: MediaBarViewController!
    private var voiceChannelStateObserverToken: Any?
    private var conversationObserverToken: Any?
    private var titleView: ConversationTitleView!
    private var conversationListObserverToken: Any?
    
    var participantsController: UIViewController? {
        
        var viewController: UIViewController? = nil
        
        switch conversation.conversationType {
        case .group:
            let groupDetailsViewController = GroupDetailsViewController(conversation: conversation)
            viewController = groupDetailsViewController
        case .`self`, .oneOnOne, .connection:
            viewController = createUserDetailViewController()
        case .invalid:
            fatal("Trying to open invalid conversation")
        default:
            break
        }
        
        
        let _participantsController = viewController?.wrapInNavigationController()
        
        return _participantsController
        
    }

    deinit {
        dismissCollectionIfNecessary()
        
        hideAndDestroyParticipantsPopover()
        contentViewController.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let session = session as? ZMUserSession {
            conversationListObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversations(inUserSession: session), userSession: session)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        UIView.performWithoutAnimation({
            self.view.backgroundColor = UIColor.from(scheme: .textBackground)
        })
        
        createInputBarController()
        createContentViewController()
        
        contentViewController.tableView.pannableView = inputBarController.view
        
        createConversationBarController()
        createMediaBarViewController()
        createGuestsBarController()
        
        addToSelf(contentViewController)
        addToSelf(inputBarController)
        addToSelf(conversationBarController)
        
        updateOutgoingConnectionVisibility()
        isAppearing = false
        createConstraints()
        updateInputBarVisibility()
        
        if let quote = conversation.draftMessage?.quote,
            !quote.hasBeenDeleted {            inputBarController.addReplyComposingView(contentViewController.createReplyComposingView(for: quote))
        }
    }
    
    func createOutgoingConnectionViewController() {
        outgoingConnectionViewController = OutgoingConnectionViewController()
        outgoingConnectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        outgoingConnectionViewController.buttonCallback = { [weak self] action in
            self?.session?.enqueueChanges({
                switch action {
                case .cancel:
                    self?.conversation.connectedUser?.cancelConnectionRequest()
                case .archive:
                    self?.conversation.isArchived = true
                default:
                    break
                }
            })
            
            self?.openConversationList()
        }
    }
    
    func createGuestsBarController() {
        guestsBarController = GuestsBarController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isAppearing = true
        updateGuestsBarVisibility()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateGuestsBarVisibility()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateLeftNavigationBarItems()
        ZMUserSession.shared()?.didClose(conversation: conversation)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateLeftNavigationBarItems()
    }
    
    func scroll(to message: ZMConversationMessage?) {
        contentViewController.scroll(to: message, completion: nil)
    }
    
    func createConversationBarController() {
        conversationBarController = BarController()
    }
    
    // MARK: - Device orientation
    func shouldAutorotate() -> Bool {
        return true
    }
    
    func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            
        }) { context in
            self.updateLeftNavigationBarItems()
        }
        
        super.viewWillTransition(to: size, with: coordinator)
        
        hideAndDestroyParticipantsPopover()
    }
    
    func definesPresentationContext() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if collectionController?.view.window == nil {
            collectionController = nil
        }
    }
    
    func openConversationList() {
        guard let leftControllerRevealed = wr_splitViewController?.isLeftViewControllerRevealed else { return }
        wr_splitViewController?.setLeftViewControllerRevealed(!leftControllerRevealed, animated: true, completion: nil)
    }
    
    // MARK: - Getters, setters
    
    func setCollection(_ collectionController: CollectionsViewController?) {
        self.collectionController = collectionController
        
        updateLeftNavigationBarItems()
    }
    
    // MARK: - SwipeNavigationController's panning
    ///TODO: still needed?
    /*
    func frameworkShouldRecognizePan(_ gestureRecognizer: UIPanGestureRecognizer?) -> Bool {
        let location = gestureRecognizer?.location(in: view)
        if view.convert(inputBarController.view.bounds, from: inputBarController.view).contains(location) {
            return false
        }
        
        return true
    }*/
    
    // MARK: - Application Events & Notifications
    override func accessibilityPerformEscape() -> Bool {
        openConversationList()
        return true
    }
    
    @objc
    func onBackButtonPressed(_ backButton: UIButton?) {
        openConversationList()
    }
    
    @objc
    func addParticipants(_ participants: Set<ZMUser>) {
        var newConversation: ZMConversation? = nil
        
        session?.enqueueChanges({
            newConversation = self.conversation.addParticipantsOrCreateConversation(participants)
        }, completionHandler: { [weak self] in
            if let newConversation = newConversation {
                self?.zClientViewController?.select(conversation: newConversation, focusOnView: true, animated: true)
            }
        })
    }
    
    private func createContentViewController() {
        contentViewController = ConversationContentViewController(conversation: conversation,
                                                                  message: visibleMessage,
                                                                  mediaPlaybackManager: zClientViewController?.mediaPlaybackManager,
                                                                  session: session!)
        contentViewController.delegate = self
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.bottomMargin = 16
        inputBarController.mentionsView = contentViewController.mentionsSearchResultsViewController
        contentViewController.mentionsSearchResultsViewController.delegate = inputBarController
    }
    
    private func createMediaBarViewController() {
        mediaBarViewController = MediaBarViewController(mediaPlaybackManager: ZClientViewController.shared?.mediaPlaybackManager)
        mediaBarViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMediaBar(_:))))
    }
    
    @objc
    func didTapMediaBar(_ tapGestureRecognizer: UITapGestureRecognizer?) {
        if let mediaPlayingMessage = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage,
            conversation == mediaPlayingMessage.conversation {
            contentViewController.scroll(to: mediaPlayingMessage, completion: nil)
        }
    }
    
    private func createInputBarController() {
        inputBarController = ConversationInputBarViewController(conversation: conversation)
        inputBarController.delegate = self
        inputBarController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Create an invisible input accessory view that will allow us to take advantage of built in keyboard
        // dragging and sizing of the scrollview
        invisibleInputAccessoryView = InvisibleInputAccessoryView()
        invisibleInputAccessoryView.delegate = self
        invisibleInputAccessoryView.isUserInteractionEnabled = false // make it not block touch events
        invisibleInputAccessoryView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        if !AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal {
            inputBarController.inputBar.invisibleInputAccessoryView = invisibleInputAccessoryView
        }
    }
    
    private func updateInputBarVisibility() {
        if conversation.isReadOnly {
            inputBarController.inputBar.textView.resignFirstResponder()
            inputBarController.dismissMentionsIfNeeded()
            inputBarController.removeReplyComposingView()
        }
        
        inputBarZeroHeight?.isActive = conversation.isReadOnly
        view.setNeedsLayout()
    }
    
    private func setupNavigatiomItem() {
        titleView = ConversationTitleView(conversation: conversation, interactive: true)
        
        titleView.tapHandler = { [weak self] button in
            if let superview = self?.titleView.superview,
                let participantsController = self?.participantsController {
                self?.presentParticipantsViewController(participantsController, from: superview)
            }
        }
        titleView.configure()
        
        navigationItem.titleView = titleView
        navigationItem.leftItemsSupplementBackButton = false
        
        updateRightNavigationItemsButtons()
    }
    
    
    //MARK: - ParticipantsPopover
    
    private func hideAndDestroyParticipantsPopover() {
        if (presentedViewController is GroupDetailsViewController) || (presentedViewController is ProfileViewController) {
            dismiss(animated: true)
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if (controller.presentedViewController is AddParticipantsViewController) {
            return .overFullScreen
        }
        return .fullScreen
    }
}
//MARK: - InvisibleInputAccessoryViewDelegate

extension ConversationViewController: InvisibleInputAccessoryViewDelegate {
    
    // WARNING: DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING
    func invisibleInputAccessoryView(_ invisibleInputAccessoryView: InvisibleInputAccessoryView, superviewFrameChanged frame: CGRect?) {
        // Adjust the input bar distance from bottom based on the invisibleAccessoryView
        var distanceFromBottom: CGFloat = 0
        
        // On iOS 8, the frame goes to zero when the accessory view is hidden
        if frame?.equalTo(.zero) == false {
            
            let convertedFrame = view.convert(invisibleInputAccessoryView.superview?.frame ?? .zero, from: invisibleInputAccessoryView.superview?.superview)
            
            // We have to use intrinsicContentSize here because the frame may not have actually been updated yet
            let newViewHeight = invisibleInputAccessoryView.intrinsicContentSize.height
            
            distanceFromBottom = view.frame.size.height - convertedFrame.origin.y - newViewHeight
            
            distanceFromBottom = max(0, distanceFromBottom)
        }
        
        let closure: () -> () = {
            self.inputBarBottomMargin?.constant = -distanceFromBottom
            self.view.layoutIfNeeded()
        }
        
        if isAppearing {
            UIView.performWithoutAnimation(closure)
        } else {
            closure()
        }        
    }
}

//MARK: - ZMConversationObserver

extension ConversationViewController: ZMConversationObserver {
    public func conversationDidChange(_ note: ConversationChangeInfo) {
        if note.causedByConversationPrivacyChange {
            presentPrivacyWarningAlert(for: note)
        }
        
        if note.participantsChanged ||
            note.connectionStateChanged {
            updateRightNavigationItemsButtons()
            updateLeftNavigationBarItems()
            updateOutgoingConnectionVisibility()
            contentViewController.updateTableViewHeaderView()
            updateInputBarVisibility()
        }
        
        if note.participantsChanged ||
            note.externalParticipantsStateChanged {
            updateGuestsBarVisibility()
        }
        
        if note.nameChanged ||
            note.securityLevelChanged ||
            note.connectionStateChanged ||
            note.legalHoldStatusChanged {
            setupNavigatiomItem()
        }
    }
    
    func dismissProfileClientViewController(_ sender: UIBarButtonItem?) {
        dismiss(animated: true)
    }
}

//MARK: - ZMConversationListObserver

extension ConversationViewController: ZMConversationListObserver {
    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateLeftNavigationBarItems()
    }
    
    public func conversation(inside list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        updateLeftNavigationBarItems()
    }
}

//MARK: - InputBar

extension ConversationViewController: ConversationInputBarViewControllerDelegate {
    func inputBar(didComposeText text: String?, mentions: [Mention]?, replyingTo message: ZMConversationMessage?) {
        contentViewController.scrollToBottom()
        inputBarController.sendController.sendTextMessage(text, mentions: mentions, replyingTo: message)
    }
    
    func conversationInputBarViewControllerShouldBeginEditing(_ controller: ConversationInputBarViewController) -> Bool {
        if !contentViewController.isScrolledToBottom && !controller.isEditingMessage &&
            !controller.isReplyingToMessage {
            collectionController = nil
            contentViewController.searchQueries = []
            contentViewController.scrollToBottom()
        }
        
        setGuestBarForceHidden(true)
        return true
    }
    
    func conversationInputBarViewControllerShouldEndEditing(_ controller: ConversationInputBarViewController) -> Bool {
        setGuestBarForceHidden(false)
        return true
    }
    
    func conversationInputBarViewControllerDidFinishEditing(_ message: ZMConversationMessage, withText newText: String?, mentions: [Mention]) {
        contentViewController.didFinishEditing(message)
        session?.enqueueChanges({
            if let newText = newText,
                !newText.isEmpty {
                let fetchLinkPreview = !Settings.shared().disableLinkPreviews
                message.textMessageData?.editText(newText, mentions: mentions, fetchLinkPreview: fetchLinkPreview)
            } else {
                ZMMessage.deleteForEveryone(message)
            }
        })
    }
    
    func conversationInputBarViewControllerDidCancelEditing(_ message: ZMConversationMessage) {
        contentViewController.didFinishEditing(message)
    }
    
    func conversationInputBarViewControllerWants(toShow message: ZMConversationMessage) {
        contentViewController.scroll(to: message) { cell in
            self.contentViewController.highlight(message)
        }
    }
    
    func conversationInputBarViewControllerEditLastMessage() {
        contentViewController.editLastMessage()
    }
    
}
