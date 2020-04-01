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
import MobileCoreServices

enum ConversationInputBarViewControllerMode {
    case textInput
    case audioRecord
    case camera
    case timeoutConfguration
}

final class ConversationInputBarViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    private(set) var photoButton: IconButton!
    private(set) var ephemeralIndicatorButton: IconButton!
    private(set) var markdownButton: IconButton!
    private(set) var mentionButton: IconButton!
    private(set) var inputBar: InputBar!
    let conversation: ZMConversation
    weak var delegate: ConversationInputBarViewControllerDelegate?
    var mode: ConversationInputBarViewControllerMode = .textInput {
        didSet {
            guard oldValue != mode else {
                return
            }
            
            switch mode {
            case .textInput:
                asssignInputController(nil)
                inputController = nil
                singleTapGestureRecognizer?.isEnabled = false
                selectInputControllerButton(nil)
            case .audioRecord:
                clearTextInputAssistentItemIfNeeded()
                if inputController == nil || inputController != audioRecordKeyboardViewController {
                    if audioRecordKeyboardViewController == nil {
                        audioRecordKeyboardViewController = AudioRecordKeyboardViewController()
                        audioRecordKeyboardViewController?.delegate = self
                    }
                    
                    asssignInputController(audioRecordKeyboardViewController)
                }
                singleTapGestureRecognizer?.isEnabled = true
                selectInputControllerButton(audioButton)
            case .camera:
                clearTextInputAssistentItemIfNeeded()
                if inputController == nil || inputController != cameraKeyboardViewController {
                    if cameraKeyboardViewController == nil {
                        createCameraKeyboardViewController()
                    }
                    
                    asssignInputController(cameraKeyboardViewController)
                }
                singleTapGestureRecognizer?.isEnabled = true
                selectInputControllerButton(photoButton)
            case .timeoutConfguration:
                clearTextInputAssistentItemIfNeeded()
                if inputController == nil || inputController != ephemeralKeyboardViewController {
                    if ephemeralKeyboardViewController == nil {
                        createEphemeralKeyboardViewController()
                    }
                    
                    asssignInputController(ephemeralKeyboardViewController)
                }
                singleTapGestureRecognizer?.isEnabled = true
                selectInputControllerButton(hourglassButton)
            }
            
            updateRightAccessoryView()

        }
    }
    private(set) var inputController: UIViewController?
    var mentionsHandler: MentionsHandler?
    weak var mentionsView: (Dismissable & UserList & KeyboardCollapseObserver)?
    var textfieldObserverToken: Any?
    weak var audioSession: AVAudioSessionType!
    
    private var audioButton: IconButton!
//    private var photoButton: IconButton!
//    private var uploadFileButton: IconButton!
    private var sketchButton: IconButton!
    private var pingButton: IconButton!
    private var locationButton: IconButton!
//    private var ephemeralIndicatorButton: IconButton!
//    private var markdownButton: IconButton!
    private var gifButton: IconButton!
//    private var mentionButton: IconButton!
    private var sendButton: IconButton!
    private var hourglassButton: IconButton!
    private var videoButton: IconButton!
//    private var inputBar: InputBar!
    var typingIndicatorView: TypingIndicatorView?
    private var audioRecordViewController: AudioRecordViewController?
    private var audioRecordViewContainer: UIView?
    private var audioRecordKeyboardViewController: AudioRecordKeyboardViewController?
    private var cameraKeyboardViewController: CameraKeyboardViewController?
    private var ephemeralKeyboardViewController: EphemeralKeyboardViewController?
    private var sendController: ConversationInputBarSendController!
    var editingMessage: ZMConversationMessage?
    private weak var quotedMessage: ZMConversationMessage?
    private var replyComposingView: ReplyComposingView?
    private var impactFeedbackGenerator: UIImpactFeedbackGenerator?
    private var shouldRefocusKeyboardAfterImagePickerDismiss = false
    // Counter keeping track of calls being made when the audio keyboard ewas visible before.
    private var callCountWhileCameraKeyboardWasVisible = 0
    private var callStateObserverToken: Any?
    private var wasRecordingBeforeCall = false
    private var sendButtonState: ConversationInputBarButtonState!
    private var inRotation = false

    // PopoverPresenter

    private weak var presentedPopover: UIPopoverPresentationController?
    private weak var popoverPointToView: UIView?
    
    private var singleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    private var authorImageView: UserImageView?
//    private var conversation: ZMConversation?
    private var conversationObserverToken: Any?
    private var userObserverToken: Any?
//    private var inputController: UIViewController?
    private var typingObserverToken: Any?
    private var notificationFeedbackGenerator: UINotificationFeedbackGenerator?
    
    // MARK: - Input views handling

    /// init with a ZMConversation objcet
    /// - Parameter conversation: provide nil only for tests
    /// - Returns: a ConversationInputBarViewController
    
    init(conversation: ZMConversation) {
        self.conversation = conversation

        super.init(nibName: nil, bundle: nil)
        setupAudioSession()
        
            sendController = ConversationInputBarSendController(conversation: self.conversation)
            conversationObserverToken = ConversationChangeInfo.addObserver(self, forConversation: self.conversation)
            typingObserverToken = conversation.addTypingObserver(self)
        
        sendButtonState = ConversationInputBarButtonState()
        
        setupNotificationCenter()
        
        setupInputLanguageObserver()
        
        notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCallStateObserver()
        setupAppLockedObserver()
        
        createSingleTapGestureRecognizer()
        
        
        if conversation.hasDraftMessage {
            inputBar.textView.setDraftMessage(conversation.draftMessage)
        }
        
        configureAudioButton(audioButton)
        configureMarkdownButton()
        configureMentionButton()
        configureEphemeralKeyboardButton(hourglassButton)
        configureEphemeralKeyboardButton(ephemeralIndicatorButton)
        
        sendButton.addTarget(self, action: #selector(sendButtonPressed(_:)), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(cameraButtonPressed(_:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(videoButtonPressed(_:)), for: .touchUpInside)
        sketchButton.addTarget(self, action: #selector(sketchButtonPressed(_:)), for: .touchUpInside)
        uploadFileButton.addTarget(self, action: #selector(docUploadPressed(_:)), for: .touchUpInside)
        pingButton.addTarget(self, action: #selector(pingButtonPressed(_:)), for: .touchUpInside)
        gifButton.addTarget(self, action: #selector(giphyButtonPressed(_:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(locationButtonPressed(_:)), for: .touchUpInside)
        
        if conversationObserverToken == nil && conversation != nil {
            conversationObserverToken = ConversationChangeInfo.addObserver(self, forConversation: conversation)
        }
        
        if userObserverToken == nil && conversation.connectedUser != nil && ZMUserSession.sharedSession != nil {
            userObserverToken = UserChangeInfo.addObserver(self, forUser: conversation.connectedUser, inUserSession: ZMUserSession.sharedSession)
        }
        
        updateAccessoryViews()
        updateInputBarVisibility()
        updateTypingIndicator()
        updateWritingState(animated: false)
        updateButtonIcons()
        updateAvailabilityPlaceholder()
        
        setInputLanguage()
        setupStyle()
        
        if #available(iOS 11.0, *) {
            let interaction = UIDropInteraction(delegate: self)
            inputBar.textView.addInteraction(interaction)
        }
    }
    
    func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRightAccessoryView()
        inputBar.updateReturnKey()
        inputBar.updateEphemeralState()
        updateMentionList()
    }
    
    func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputBar.textView.endEditing(true)
    }
    
    func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        endEditingMessageIfNeeded()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ephemeralIndicatorButton.layer.cornerRadius = ephemeralIndicatorButton.bounds.width / 2
    }
    
    // MARK: - setup
    private func setupStyle() {
        ephemeralIndicatorButton.borderWidth = 0
        ephemeralIndicatorButton.titleLabel?.font = UIFont.smallSemiboldFont
        hourglassButton.setIconColor(.from(scheme: .iconNormal), for: .normal)
        hourglassButton.setIconColor(.from(scheme: .iconHighlighted), for: .highlighted)
        hourglassButton.setIconColor(.from(scheme: .iconNormal), for: .selected)
        
        hourglassButton.setBackgroundImageColor(.clear, for: .selected)
    }

    private func createSingleTapGestureRecognizer() {
        singleTapGestureRecognizer.addTarget(self, action: #selector(onSingleTap(_:)))
        singleTapGestureRecognizer.enabled = false
        singleTapGestureRecognizer.delegate = self
        singleTapGestureRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(singleTapGestureRecognizer)
    }

    func updateRightAccessoryView() {
        updateEphemeralIndicatorButtonTitle(ephemeralIndicatorButton)
        
        let trimmed = inputBar.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        sendButtonState.update(withTextLength: trimmed.count, editing: nil != editingMessage, markingDown: inputBar.isMarkingDown, destructionTimeout: conversation.messageDestructionTimeoutValue, conversationType: conversation.conversationType, mode: mode, syncedMessageDestructionTimeout: conversation.hasSyncedMessageDestructionTimeout)
        
        sendButton.hidden = sendButtonState.sendButtonHidden
        hourglassButton.hidden = sendButtonState.hourglassButtonHidden
        ephemeralIndicatorButton.hidden = sendButtonState.ephemeralIndicatorButtonHidden
        ephemeralIndicatorButton.enabled = sendButtonState.ephemeralIndicatorButtonEnabled
        
        ephemeralIndicatorButton.setBackgroundImage(conversation.timeoutImage, for: .normal)
        ephemeralIndicatorButton.setBackgroundImage(conversation.disabledTimeoutImage, for: .disabled)
    }
    
    func updateMentionList() {
        triggerMentionsIfNeeded(from: inputBar.textView, with: nil)
    }

    
    private func updateRightAccessoryView() {
    }
    
    func clearInputBar() {
        inputBar.textView.text = ""
        inputBar.markdownView.resetIcons()
        inputBar.textView.resetMarkdown()
        updateRightAccessoryView()
        conversation.setIsTyping(false)
        replyComposingView?.removeFromSuperview()
        replyComposingView = nil
        quotedMessage = nil
    }

    func updateNewButtonTitleLabel() {
        photoButton.titleLabel?.isHidden = inputBar.textView.isFirstResponder
    }

    func updateLeftAccessoryView() {
        authorImageView?.alpha = inputBar.textView.isFirstResponder ? 1 : 0
    }

    @objc
    func updateAccessoryViews() {
        updateLeftAccessoryView()
        updateRightAccessoryView()
    }

    @objc
    func updateAvailabilityPlaceholder() {
        guard ZMUser.selfUser().hasTeam,
            conversation.conversationType == .oneOnOne,
            let connectedUser = conversation.connectedUser else {
                return
        }

        inputBar.availabilityPlaceholder = AvailabilityStringBuilder.string(for: connectedUser, with: .placeholder, color: inputBar.placeholderColor)
    }

    @objc
    func updateInputBarVisibility() {
        view.isHidden = conversation.isReadOnly
    }

    // MARK: - Save draft message
    func draftMessage(from textView: MarkdownTextView) -> DraftMessage {
        let (text, mentions) = textView.preparedText

        return DraftMessage(text: text, mentions: mentions, quote: quotedMessage as? ZMMessage)
    }

    private func didEnterBackground() {
        if !inputBar.textView.text.isEmpty {
            conversation.setIsTyping(false)
        }

        let draft = draftMessage(from: inputBar.textView)
        delegate?.conversationInputBarViewControllerDidComposeDraft(message: draft)
    }

    @objc
    func updateButtonIcons() {
        audioButton.setIcon(.microphone, size: .tiny, for: .normal)

        videoButton.setIcon(.videoMessage, size: .tiny, for: .normal)

        photoButton.setIcon(.cameraLens, size: .tiny, for: .normal)

        uploadFileButton.setIcon(.paperclip, size: .tiny, for: .normal)

        sketchButton.setIcon(.brush, size: .tiny, for: .normal)

        pingButton.setIcon(.ping, size: .tiny, for: .normal)

        locationButton.setIcon(.locationPin, size: .tiny, for: .normal)

        gifButton.setIcon(.gif, size: .tiny, for: .normal)

        mentionButton.setIcon(.mention, size: .tiny, for: .normal)

        sendButton.setIcon(.send, size: .tiny, for: .normal)
    }
    
    func selectInputControllerButton(_ button: IconButton?) {
        for otherButton in [photoButton, audioButton, hourglassButton] {
            otherButton.selected = button == otherButton
        }
    }
    
    func clearTextInputAssistentItemIfNeeded() {
        if nil != UITextInputAssistantItem.self {
            let item = inputBar.textView.inputAssistantItem
            item.leadingBarButtonGroups = []
            item.trailingBarButtonGroups = []
        }
    }
    

    func postImage(_ image: MediaAsset) {
        guard let data = image.imageData else { return }
        sendController.sendMessage(withImageData: data)
    }

    ///TODO: chnage to didSet after ConversationInputBarViewController is converted to Swift
    @objc
    func asssignInputController(_ inputController: UIViewController?) {
        self.inputController?.view.removeFromSuperview()

        self.inputController = inputController
        deallocateUnusedInputControllers()

        if let inputController = inputController {
            let inputViewSize = UIView.lastKeyboardSize

            let inputViewFrame: CGRect = CGRect(origin: .zero, size: inputViewSize)
            let inputView = UIInputView(frame: inputViewFrame, inputViewStyle: .keyboard)
            inputView.allowsSelfSizing = true

            inputView.autoresizingMask = .flexibleWidth
            inputController.view.frame = inputView.frame
            inputController.view.autoresizingMask = .flexibleWidth
            if let view = inputController.view {
                inputView.addSubview(view)
            }

            inputBar.textView.inputView = inputView
        } else {
            inputBar.textView.inputView = nil
        }

        inputBar.textView.reloadInputViews()
    }

    func deallocateUnusedInputControllers() {
        if cameraKeyboardViewController != inputController {
            cameraKeyboardViewController = nil
        }
        if audioRecordKeyboardViewController != inputController {
            audioRecordKeyboardViewController = nil
        }
        if ephemeralKeyboardViewController != inputController {
            ephemeralKeyboardViewController = nil
        }
    }

    // MARK: - PingButton

    @objc
    func pingButtonPressed(_ button: UIButton?) {
        appendKnock()
    }

    private func appendKnock() {
        notificationFeedbackGenerator.prepare()
        ZMUserSession.shared()?.enqueue({

            if self.conversation.appendKnock() != nil {
                Analytics.shared().tagMediaActionCompleted(.ping, inConversation: self.conversation)

                AVSMediaManager.sharedInstance().playKnockSound()
                self.notificationFeedbackGenerator.notificationOccurred(.success)
            }
        })

        pingButton.isEnabled = false
        delay(0.5) {
            self.pingButton.isEnabled = true
        }
    }

    // MARK: - SendButton

    @objc
    func sendButtonPressed(_ sender: Any?) {
        inputBar.textView.autocorrectLastWord()
        sendText()
    }

    // MARK: - Giphy

    @objc
    func giphyButtonPressed(_ sender: Any?) {
        guard !AppDelegate.isOffline else { return }

        let giphySearchViewController = GiphySearchViewController(searchTerm: "", conversation: conversation)
        giphySearchViewController.delegate = self
        ZClientViewController.shared?.present(giphySearchViewController.wrapInsideNavigationController(), animated: true)
    }

    // MARK: - Animations
    func bounceCameraIcon() {
        let scaleTransform = CGAffineTransform(scaleX: 1.3, y: 1.3)

        let scaleUp = {
                self.photoButton.transform = scaleTransform
            }

        let scaleDown = {
                self.photoButton.transform = CGAffineTransform.identity
            }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: scaleUp) { finished in
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: scaleDown)
        }
    }

    // MARK: - Haptic Feedback
    func playInputHapticFeedback() {
        impactFeedbackGenerator?.prepare()
        impactFeedbackGenerator?.impactOccurred()
    }

    // MARK: - Input views handling
    @objc
    func onSingleTap(_ recognier: UITapGestureRecognizer?) {
        if recognier?.state == .recognized {
            mode = .textInput
        }
    }

    // MARK: - notification center
    @objc //TODO: no objc
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { [weak self] _ in
            guard let weakSelf = self else { return }
            
            let inRotation = weakSelf.inRotation
            let isRecording = weakSelf.audioRecordKeyboardViewController?.isRecording ?? false
            
            if !inRotation && !isRecording {
                weakSelf.mode = .textInput
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.didEnterBackground()
        }
    }

    // MARK: - Keyboard Shortcuts
    override open var canBecomeFirstResponder: Bool {
        return true
    }

}

// MARK: - GiphySearchViewControllerDelegate

extension ConversationInputBarViewController: GiphySearchViewControllerDelegate {
    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String) {
        clearInputBar()
        dismiss(animated: true) {
            let messageText: String

            if (searchTerm == "") {
                messageText = String(format: "giphy.conversation.random_message".localized, searchTerm)
            } else {
                messageText = String(format: "giphy.conversation.message".localized, searchTerm)
            }

            self.sendController.sendTextMessage(messageText, mentions: [], withImageData: imageData)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ConversationInputBarViewController: UIImagePickerControllerDelegate {

    ///TODO: check this is still necessary on iOS 13?
    private func statusBarBlinksRedFix() {
        // Workaround http://stackoverflow.com/questions/26651355/
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
        }
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        statusBarBlinksRedFix()

        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String

        if mediaType == kUTTypeMovie as String {
            processVideo(info: info, picker: picker)
        } else if mediaType == kUTTypeImage as String {
            let image: UIImage? = (info[UIImagePickerController.InfoKey.editedImage] as? UIImage) ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage

            if let image = image, let jpegData = image.jpegData(compressionQuality: 0.9) {
                if picker.sourceType == UIImagePickerController.SourceType.camera {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    // In case of picking from the camera, the iOS controller is showing it's own confirmation screen.
                    parent?.dismiss(animated: true) {
                        self.sendController.sendMessage(withImageData: jpegData, completion: nil)
                    }
                } else {
                    parent?.dismiss(animated: true) {
                        self.showConfirmationForImage(jpegData, isFromCamera: false, uti: mediaType)
                    }
                }

            }
        } else {
            parent?.dismiss(animated: true)
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        statusBarBlinksRedFix()

        parent?.dismiss(animated: true) {

            if self.shouldRefocusKeyboardAfterImagePickerDismiss {
                self.shouldRefocusKeyboardAfterImagePickerDismiss = false
                self.mode = .camera
                self.inputBar.textView.becomeFirstResponder()
            }
        }
    }

    // MARK: - Sketch

    @objc
    func sketchButtonPressed(_ sender: Any?) {
        inputBar.textView.resignFirstResponder()

        let viewController = CanvasViewController()
        viewController.delegate = self
        viewController.title = conversation.displayName.uppercased()

        parent?.present(viewController.wrapInNavigationController(), animated: true)
    }
}

// MARK: - Informal TextView delegate methods

extension ConversationInputBarViewController: InformalTextViewDelegate {
    func textView(_ textView: UITextView, hasImageToPaste image: MediaAsset) {
        let context = ConfirmAssetViewController.Context(asset: .image(mediaAsset: image),
                                                         onConfirm: {[weak self] editedImage in
                                                            self?.dismiss(animated: false)
                                                            self?.postImage(editedImage ?? image)
            },
                                                         onCancel: { [weak self] in
                                                            self?.dismiss(animated: false)
            }
        )

        let confirmImageViewController = ConfirmAssetViewController(context: context)

        confirmImageViewController.previewTitle = conversation.displayName.uppercasedWithCurrentLocale

        present(confirmImageViewController, animated: false)
    }

    func textView(_ textView: UITextView, firstResponderChanged resigned: Bool) {
        updateAccessoryViews()
        updateNewButtonTitleLabel()
    }
}

// MARK: - ZMConversationObserver

extension ConversationInputBarViewController: ZMConversationObserver {
    public func conversationDidChange(_ change: ConversationChangeInfo) {
        if change.participantsChanged ||
            change.connectionStateChanged {
            updateInputBarVisibility()
        }

        if change.destructionTimeoutChanged {
            updateAccessoryViews()
            updateInputBar()
        }
    }
}

// MARK: - ZMUserObserver

extension ConversationInputBarViewController: ZMUserObserver {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.availabilityChanged {
            updateAvailabilityPlaceholder()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ConversationInputBarViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return singleTapGestureRecognizer == gestureRecognizer || singleTapGestureRecognizer == otherGestureRecognizer
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if singleTapGestureRecognizer == gestureRecognizer {
            return true
        }

        return gestureRecognizer.view?.bounds.contains(touch.location(in: gestureRecognizer.view)) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPanGestureRecognizer
    }
}
