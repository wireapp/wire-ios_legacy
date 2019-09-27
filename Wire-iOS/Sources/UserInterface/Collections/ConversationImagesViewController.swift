//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

typealias DismissAction = (_ completion: (()->())?)->()

final class ConversationImagesViewController: TintColorCorrectedViewController {
    
    let collection: AssetCollectionWrapper

    var pageViewController: UIPageViewController = UIPageViewController(transitionStyle:.scroll, navigationOrientation:.horizontal, options: [:])
    var buttonsBar: InputBarButtonsView!
    let deleteButton = IconButton(style: .default)
    let overlay = FeedbackOverlayView()
    let separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(scheme: .separator)
        return view
    }()
    fileprivate let likeButton = IconButton(style: .default)
    
    internal let inverse: Bool

    public var currentActionController: ConversationMessageActionController?

    public weak var messageActionDelegate: MessageActionResponder? = .none {
        didSet {
            updateActionControllerForMessage()
        }
    }

    public var snapshotBackgroundView: UIView? = .none
    
    fileprivate var imageMessages: [ZMConversationMessage] = []
    
    internal var currentMessage: ZMConversationMessage {
        didSet {
            self.updateButtonsForMessage()
            self.createNavigationTitle()
            self.updateActionControllerForMessage()
        }
    }

    public var isPreviewing: Bool = false {
        didSet {
            updateBarsForPreview()
        }
    }
    
    public var swipeToDismiss: Bool = false {
        didSet {
            if let currentController = self.currentController {
                currentController.swipeToDismiss = self.swipeToDismiss
            }
        }
    }
    
    public var dismissAction: DismissAction? = .none {
        didSet {
            if let currentController = self.currentController {
                currentController.dismissAction = self.dismissAction
            }
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    
    init(collection: AssetCollectionWrapper, initialMessage: ZMConversationMessage, inverse: Bool = false) {
        assert(initialMessage.isImage)
        
        self.inverse = inverse
        self.collection = collection
        self.currentMessage = initialMessage

        super.init(nibName: .none, bundle: .none)
        let imagesMatch = CategoryMatch(including: .image, excluding: .GIF)
        
        self.imageMessages = self.collection.assetCollection.assets(for: imagesMatch)
        self.collection.assetCollectionDelegate.add(self)
        
        self.createNavigationTitle()
    }
    
    deinit {
        self.collection.assetCollectionDelegate.remove(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationBar = navigationController?.navigationBar {
            navigationBar.isTranslucent = true
            navigationBar.barTintColor = UIColor.from(scheme: .barBackground)
        }

        updateStatusBar()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateStatusBar()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        self.createPageController()
        self.createControlsBar()
        view.addSubview(overlay)
        view.addSubview(separator)

        createConstraints()

        updateBarsForPreview()

        view.backgroundColor = .from(scheme: .background)
    }

    private func createConstraints() {
        [pageViewController.view,
         buttonsBar,
         overlay,
         separator].forEach(){ $0.translatesAutoresizingMaskIntoConstraints = false }

        pageViewController.view.fitInSuperview()
        buttonsBar.fitInSuperview(exclude: [.top])
        overlay.pin(to: buttonsBar)

        separator.heightAnchor.constraint(equalToConstant: .hairline).isActive = true
        separator.pin(to: buttonsBar, exclude: [.bottom])
    }
    
    private func createPageController() {
        pageViewController.delegate = self
        pageViewController.dataSource = self
        pageViewController.setViewControllers([self.imageController(for: self.currentMessage)], direction: .forward, animated: false, completion: .none)
        
        addToSelf(pageViewController)
    }
    
    fileprivate func logicalPreviousIndex(for index: Int) -> Int? {
        if self.inverse {
            return self.nextIndex(for: index)
        }
        else {
            return self.previousIndex(for: index)
        }
    }
    
    fileprivate func previousIndex(for index: Int) -> Int? {
        let nextIndex = index - 1

        guard nextIndex >= 0 else {
            return .none
        }
        
        return nextIndex
    }
    
    fileprivate func logicalNextIndex(for index: Int) -> Int? {
        if self.inverse {
            return self.previousIndex(for: index)
        }
        else {
            return self.nextIndex(for: index)
        }
    }
    
    fileprivate func nextIndex(for index: Int) -> Int? {
        let nextIndex = index + 1
        guard self.imageMessages.count > nextIndex else {
            return .none
        }
        
        return nextIndex
    }

    private func createControlsBarButtons() -> [IconButton] {
        var buttons = [IconButton]()

        // ephemermal images should not contain these buttons.
        // if the current message is ephemeral, then it will be the only
        // message b/c ephemeral messages are excluded in the collection.
        if !currentMessage.isEphemeral {

            let copyButton = IconButton(style: .default)
            copyButton.setIcon(.copy, size: .tiny, for: .normal)
            copyButton.accessibilityLabel = "copy"
            copyButton.addTarget(self, action: #selector(ConversationImagesViewController.copyCurrent(_:)), for: .touchUpInside)

            likeButton.addTarget(self, action: #selector(likeCurrent), for: .touchUpInside)
            updateLikeButton()

            let saveButton = IconButton(style: .default)
            saveButton.setIcon(.save, size: .tiny, for: .normal)
            saveButton.accessibilityLabel = "save"
            saveButton.addTarget(self, action: #selector(ConversationImagesViewController.saveCurrent(_:)), for: .touchUpInside)

            let shareButton = IconButton(style: .default)
            shareButton.setIcon(.export, size: .tiny, for: .normal)
            shareButton.accessibilityLabel = "share"
            shareButton.addTarget(self, action: #selector(ConversationImagesViewController.shareCurrent(_:)), for: .touchUpInside)

            let sketchButton = IconButton(style: .default)
            sketchButton.setIcon(.brush, size: .tiny, for: .normal)
            sketchButton.accessibilityLabel = "sketch over image"
            sketchButton.addTarget(self, action: #selector(ConversationImagesViewController.sketchCurrent(_:)), for: .touchUpInside)

            let emojiSketchButton = IconButton(style: .default)
            emojiSketchButton.setIcon(.emoji, size: .tiny, for: .normal)
            emojiSketchButton.accessibilityLabel = "sketch emoji over image"
            emojiSketchButton.addTarget(self, action: #selector(ConversationImagesViewController.sketchCurrentEmoji(_:)), for: .touchUpInside)

            let revealButton = IconButton(style: .default)
            revealButton.setIcon(.eye, size: .tiny, for: .normal)
            revealButton.accessibilityLabel = "reveal in conversation"
            revealButton.addTarget(self, action: #selector(ConversationImagesViewController.revealCurrent(_:)), for: .touchUpInside)

            buttons = [likeButton, shareButton, sketchButton, emojiSketchButton, copyButton, saveButton, revealButton]
        }

        deleteButton.setIcon(.trash, size: .tiny, for: .normal)
        deleteButton.accessibilityLabel = "delete"
        deleteButton.addTarget(self, action: #selector(deleteCurrent), for: .touchUpInside)

        buttons.append(deleteButton)
        buttons.forEach { $0.hitAreaPadding = .zero }

        return buttons
    }
    
    private func createControlsBar() {
        let buttons = createControlsBarButtons()

        self.buttonsBar = InputBarButtonsView(buttons: buttons)
        self.buttonsBar.clipsToBounds = true
        self.buttonsBar.expandRowButton.setIconColor(UIColor.from(scheme: .textForeground), for: .normal)
        self.buttonsBar.backgroundColor = UIColor.from(scheme: .barBackground)
        self.view.addSubview(self.buttonsBar)
        
        self.updateButtonsForMessage()
    }

    fileprivate func updateLikeButton() {
        likeButton.setIcon(currentMessage.liked ? .liked : .like, size: .tiny, for: .normal)
        likeButton.accessibilityLabel = currentMessage.liked ? "unlike" : "like"
    }

    fileprivate func updateBarsForPreview() {
        buttonsBar?.isHidden = isPreviewing
        separator.isHidden = isPreviewing
    }
    
    fileprivate func imageController(for message: ZMConversationMessage) -> FullscreenImageViewController {
        let imageViewController = FullscreenImageViewController(message: message)
        imageViewController.delegate = self
        imageViewController.swipeToDismiss = self.swipeToDismiss
        imageViewController.showCloseButton = false
        imageViewController.dismissAction = self.dismissAction

        return imageViewController
    }
    
    fileprivate func indexOf(message messageToFind: ZMConversationMessage) -> Int? {
        return self.imageMessages.firstIndex(where: { (message: ZMConversationMessage) -> (Bool) in
            return message == messageToFind
        })
    }
    
    private func createNavigationTitle() {
        guard let sender = currentMessage.sender, let serverTimestamp = currentMessage.serverTimestamp else {
            return
        }
        navigationItem.titleView = TwoLineTitleView(first: sender.displayName.localizedUppercase, second: serverTimestamp.formattedDate)
    }
    
    private func updateButtonsForMessage() {
        self.deleteButton.isHidden = !currentMessage.canBeDeleted
    }

    private func updateActionControllerForMessage() {
        currentActionController = ConversationMessageActionController(responder: messageActionDelegate, message: currentMessage, context: .collection, view: view)
    }
    
    var currentController: FullscreenImageViewController? {
        get {
            guard let imageController = self.pageViewController.viewControllers?.first as? FullscreenImageViewController else {
                return .none
            }
            
            return imageController
        }
    }
    
    private func perform(action: MessageAction) {
        messageActionDelegate?.perform(action: action, for: currentMessage, view: view)
    }

    @objc public func copyCurrent(_ sender: AnyObject!) {
        let text = "collections.image_viewer.copied.title".localized(uppercased: true)
        overlay.show(text: text)
        perform(action: .copy)
    }
    
    @objc public func saveCurrent(_ sender: UIButton!) {
        if sender != nil {
            self.currentController?.performSaveImageAnimation(from: sender)
        }
        perform(action: .save)
    }

    @objc public func likeCurrent() {
        ZMUserSession.shared()?.enqueueChanges({
            self.currentMessage.liked = !self.currentMessage.liked
        }, completionHandler: {
            self.updateLikeButton()
        })
    }

    @objc public func shareCurrent(_ sender: AnyObject!) {
        perform(action: .forward)
    }

    @objc public func deleteCurrent(_ sender: AnyObject!) {
        perform(action: .delete)
    }
    
    @objc public func revealCurrent(_ sender: AnyObject!) {
        perform(action: .showInConversation)
    }
    
    @objc public func sketchCurrent(_ sender: AnyObject!) {
        perform(action: .sketchDraw)
    }
    
    @objc public func sketchCurrentEmoji(_ sender: AnyObject!) {
        perform(action: .sketchEmoji)
    }
}

extension ConversationImagesViewController: MessageActionResponder {
    func perform(action: MessageAction, for message: ZMConversationMessage!, view: UIView) {
        switch action {
        case .like: likeCurrent()
        default: self.messageActionDelegate?.perform(action: action, for: message, view: view)
        }
    }
}

extension ConversationImagesViewController: ScreenshotProvider {
    func backgroundScreenshot(for fullscreenController: FullscreenImageViewController) -> UIView? {
        return self.snapshotBackgroundView
    }
}

extension ConversationImagesViewController: AssetCollectionDelegate {
    public func assetCollectionDidFetch(collection: ZMCollection, messages: [CategoryMatch : [ZMConversationMessage]], hasMore: Bool) {
        
        for messageCategory in messages {
            let conversationMessages = messageCategory.value as [ZMConversationMessage]
            
            if messageCategory.key.including.contains(.image) {
                self.imageMessages.append(contentsOf: conversationMessages)
            }
        }
    }
    
    public func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        // no-op
    }
}

extension ConversationImagesViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewControllerPreferredInterfaceOrientationForPresentation(_ pageViewController: UIPageViewController) -> UIInterfaceOrientation {
        return .portrait
    }
    
    func pageViewControllerSupportedInterfaceOrientations(_ pageViewController: UIPageViewController) -> UIInterfaceOrientationMask {
        return self.traitCollection.horizontalSizeClass == .compact ? .portrait : .all
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.imageMessages.count
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? FullscreenImageViewController else {
            fatal("Unknown controller \(viewController)")
        }
        
        guard let messageIndex = self.indexOf(message: imageController.message),
            let nextIndex = self.logicalNextIndex(for: messageIndex) else {
                return .none
        }
        
        return self.imageController(for: self.imageMessages[nextIndex])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? FullscreenImageViewController else {
            fatal("Unknown controller \(viewController)")
        }
        
        guard let messageIndex = self.indexOf(message: imageController.message),
            let previousIndex = self.logicalPreviousIndex(for: messageIndex) else {
                return .none
        }
        
        return self.imageController(for: self.imageMessages[previousIndex])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentController = self.currentController,
            finished,
            completed {
            
            self.currentMessage = currentController.message
            self.buttonsBar.buttons = createControlsBarButtons()
            updateLikeButton()
        }
    }
}


extension ConversationImagesViewController: MenuVisibilityController {
    
    var menuVisible: Bool {
        var isVisible = buttonsBar.isHidden && separator.isHidden
        if !UIScreen.hasNotch {
            isVisible = isVisible && UIApplication.shared.isStatusBarHidden
        }

        return isVisible
    }
    
    func fadeAndHideMenu(_ hidden: Bool) {
        let duration = UIApplication.shared.statusBarOrientationAnimationDuration

        showNavigationBarVisible(hidden: hidden)

        buttonsBar.fadeAndHide(hidden, duration: duration)
        separator.fadeAndHide(hidden, duration: duration)
        
        // Don't hide the status bar on iPhone X, otherwise the navbar will go behind the notch
        if !UIScreen.hasNotch {
            UIApplication.shared.wr_setStatusBarHidden(hidden, with: .fade)
        }
    }

    private func showNavigationBarVisible(hidden: Bool) {
        let duration = UIApplication.shared.statusBarOrientationAnimationDuration

        UIView.animate(withDuration: duration, animations: {
            self.navigationController?.navigationBar.alpha = hidden ? 0 : 1
        }) { _ in
            self.navigationController?.setNavigationBarHidden(hidden, animated: false)
        }
    }
}


extension ConversationImagesViewController {

    override var previewActionItems: [UIPreviewActionItem] {
        return currentActionController?.makePreviewActions() ?? []
    }

}
