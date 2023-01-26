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
import UIKit
import WireSyncEngine

typealias DismissAction = (_ completion: Completion?) -> Void

final class ConversationImagesViewController: TintColorCorrectedViewController {

    let collection: AssetCollectionWrapper

    var pageViewController: UIPageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
    var buttonsBar: InputBarButtonsView!
    lazy var deleteButton = iconButton(messageAction: .delete)
    var shareButton: IconButton?
    let overlay = FeedbackOverlayView()
    let separator: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        return view
    }()
    lazy var likeButton = iconButton(messageAction: .like)

    let inverse: Bool

    var currentActionController: ConversationMessageActionController?

    weak var messageActionDelegate: MessageActionResponder? = .none {
        didSet {
            updateActionControllerForMessage()
        }
    }

    var snapshotBackgroundView: UIView? = .none

    fileprivate var imageMessages: [ZMConversationMessage] = []

    var currentMessage: ZMConversationMessage {
        didSet {
            self.updateButtonsForMessage()
            self.createNavigationTitle()
            self.updateActionControllerForMessage()
        }
    }

    var isPreviewing: Bool = false {
        didSet {
            updateBarsForPreview()
        }
    }

    var swipeToDismiss: Bool = false {
        didSet {
            if let currentController = self.currentController {
                currentController.swipeToDismiss = self.swipeToDismiss
            }
        }
    }

    var dismissAction: DismissAction? = .none {
        didSet {
            if let currentController = self.currentController {
                currentController.dismissAction = self.dismissAction
            }
        }
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

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.PictureView.CloseButton.description

        if let navigationBar = navigationController?.navigationBar {
            navigationBar.isTranslucent = true
            navigationBar.barTintColor = SemanticColors.View.backgroundDefault
        }
    }

    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden ?? false
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        self.buttonsBar.buttons = createControlsBarButtons()
        setupExpandRowButton()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createPageController()
        createControlsBar()
        view.addSubview(overlay)
        view.addSubview(separator)

        createConstraints()

        updateBarsForPreview()

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        [pageViewController.view,
         buttonsBar,
         overlay,
         separator].prepareForLayout()

        pageViewController.view.fitIn(view: view)
        NSLayoutConstraint.activate([
            buttonsBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonsBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.topAnchor.constraint(equalTo: buttonsBar.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: buttonsBar.bottomAnchor),
            overlay.trailingAnchor.constraint(equalTo: buttonsBar.trailingAnchor),
            overlay.leadingAnchor.constraint(equalTo: buttonsBar.leadingAnchor),

            separator.heightAnchor.constraint(equalToConstant: .hairline),
            separator.topAnchor.constraint(equalTo: buttonsBar.topAnchor),
            separator.trailingAnchor.constraint(equalTo: buttonsBar.trailingAnchor),
            separator.leadingAnchor.constraint(equalTo: buttonsBar.leadingAnchor)
        ])

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
        } else {
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
        } else {
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

    // MARK: icon buttons factory

    private func selector(for action: MessageAction) -> Selector? {
        switch action {
        case .copy:
            return #selector(copyCurrent(_:))
        case .save:
            return #selector(saveCurrent(_:))
        case .forward:
            return #selector(shareCurrent(_:))
        case .sketchDraw:
            return #selector(sketchCurrent(_:))
        case .sketchEmoji:
            return #selector(sketchCurrentEmoji(_:))
        case .showInConversation:
            return #selector(revealCurrent(_:))
        case .delete:
            return #selector(deleteCurrent)
        case .like, .unlike:
            return #selector(likeCurrent)
        default:
            return nil
        }
    }

    private func iconButton(messageAction: MessageAction) -> IconButton {
        let button = IconButton()
        button.setIcon(messageAction.icon, size: .tiny, for: .normal)
        button.accessibilityLabel = messageAction.accessibilityLabel

        if let action = selector(for: messageAction) {
            button.addTarget(self, action: action, for: .touchUpInside)
        }

        return button
    }

    private func createControlsBarButtons() -> [IconButton] {
        var buttons = [IconButton]()

        // ephemermal images should not contain these buttons.
        // if the current message is ephemeral, then it will be the only
        // message b/c ephemeral messages are excluded in the collection.
        if !currentMessage.isEphemeral {
            let copyButton = iconButton(messageAction: .copy)

            updateLikeButton()

            let saveButton = iconButton(messageAction: .save)

            let shareButton = iconButton(messageAction: .forward)

            let sketchButton = iconButton(messageAction: .sketchDraw)

            let emojiSketchButton = iconButton(messageAction: .sketchEmoji)

            let revealButton = iconButton(messageAction: .showInConversation)
            if !MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).canDownloadMedia {
                buttons = [likeButton, shareButton, sketchButton, emojiSketchButton, revealButton]
            } else {
                buttons = [likeButton, shareButton, sketchButton, emojiSketchButton, copyButton, saveButton, revealButton]
            }
        }

        buttons.append(deleteButton)
        buttons.forEach {
            $0.hitAreaPadding = .zero
            setupButtonStyle(button: $0)
        }
        return buttons
    }

    private func setupButtonStyle(button: IconButton) {
        button.layer.borderWidth = 1
        button.setIconColor(SemanticColors.Button.textInputBarItemEnabled, for: .normal)
        button.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemEnabled, for: .normal)
        button.setBorderColor(SemanticColors.Button.borderInputBarItemEnabled, for: .normal)

        button.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .highlighted)
        button.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .highlighted)
        button.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .highlighted)

        button.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .selected)
        button.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .selected)
        button.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .selected)
    }

    private func setupExpandRowButton() {
        buttonsBar.expandRowButton.layer.borderWidth = 1
        buttonsBar.expandRowButton.setIconColor(SemanticColors.Button.textInputBarItemEnabled, for: .normal)
        buttonsBar.expandRowButton.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemEnabled, for: .normal)
        buttonsBar.expandRowButton.setBorderColor(SemanticColors.Button.borderInputBarItemEnabled, for: .normal)

        buttonsBar.expandRowButton.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .highlighted)
        buttonsBar.expandRowButton.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .highlighted)
        buttonsBar.expandRowButton.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .highlighted)

        buttonsBar.expandRowButton.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .selected)
        buttonsBar.expandRowButton.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .selected)
        buttonsBar.expandRowButton.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .selected)
    }

    private func updateLikeButtonStyle() {
        if currentMessage.liked {
            likeButton.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .normal)
            likeButton.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .normal)
            likeButton.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .normal)
        } else {
            likeButton.setIconColor(SemanticColors.Button.textInputBarItemEnabled, for: .normal)
            likeButton.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemEnabled, for: .normal)
            likeButton.setBorderColor(SemanticColors.Button.borderInputBarItemEnabled, for: .normal)
        }
    }

    private func createControlsBar() {
        let buttons = createControlsBarButtons()

        buttonsBar = InputBarButtonsView(buttons: buttons)
        self.buttonsBar.clipsToBounds = true
        setupExpandRowButton()
        self.buttonsBar.backgroundColor = SemanticColors.View.backgroundDefaultWhite
        self.view.addSubview(self.buttonsBar)

        self.updateButtonsForMessage()
    }

    fileprivate func updateLikeButton() {
        let messageAction: MessageAction = currentMessage.liked ? .like : .unlike
        likeButton.setIcon(messageAction.icon, size: .tiny, for: .normal)
        updateLikeButtonStyle()
        likeButton.accessibilityLabel = messageAction.accessibilityLabel
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
        guard let sender = currentMessage.senderUser, let serverTimestamp = currentMessage.serverTimestamp else {
            return
        }
        navigationItem.titleView = TwoLineTitleView(first: (sender.name ?? "").localized, second: serverTimestamp.formattedDate)
        navigationItem.titleView?.accessibilityTraits = .header
        navigationItem.titleView?.accessibilityLabel = "\(sender.name ?? ""), \(serverTimestamp.formattedDate)"
    }

    private func updateButtonsForMessage() {
        self.deleteButton.isHidden = !currentMessage.canBeDeleted
    }

    private func updateActionControllerForMessage() {
        currentActionController = ConversationMessageActionController(responder: messageActionDelegate,
                                                                      message: currentMessage,
                                                                      context: .collection,
                                                                      view: view)
    }

    var currentController: FullscreenImageViewController? {
        guard let imageController = self.pageViewController.viewControllers?.first as? FullscreenImageViewController else {
            return .none
        }

        return imageController
    }

    private func perform(action: MessageAction,
                         for message: ZMConversationMessage? = nil,
                         sender: AnyObject?) {
        messageActionDelegate?.perform(action: action,
                                       for: message ?? currentMessage,
                                       view: sender as? UIView ?? view)
    }

    // MARK: icon button actions

    @objc
    private func copyCurrent(_ sender: AnyObject!) {
        let text = L10n.Localizable.Collections.ImageViewer.Copied.title.capitalized
        overlay.show(text: text)
        perform(action: .copy, sender: sender)
    }

    @objc
    private func saveCurrent(_ sender: UIButton!) {
        if let sender = sender {
            currentController?.performSaveImageAnimation(from: sender)
        }
        perform(action: .save, sender: sender)
    }

    @objc
    private func likeCurrent() {
        ZMUserSession.shared()?.enqueue({
            self.currentMessage.liked = !self.currentMessage.liked
        }, completionHandler: {
            self.updateLikeButton()
        })
    }

    @objc
    private func shareCurrent(_ sender: AnyObject!) {
        perform(action: .forward, sender: sender)
    }

    @objc
    private func deleteCurrent(_ sender: AnyObject!) {
        perform(action: .delete, sender: sender)
    }

    @objc
    private func revealCurrent(_ sender: AnyObject!) {
        perform(action: .showInConversation, sender: sender)
    }

    @objc
    private func sketchCurrent(_ sender: AnyObject!) {
        perform(action: .sketchDraw, sender: sender)
    }

    @objc
    private func sketchCurrentEmoji(_ sender: AnyObject!) {
        perform(action: .sketchEmoji, sender: sender)
    }
}

extension ConversationImagesViewController: MessageActionResponder {
    func perform(action: MessageAction, for message: ZMConversationMessage!, view: UIView) {
        switch action {
        case .like:
            likeCurrent()
        default:
            perform(action: action,
                    for: message,
                    sender: view)
        }
    }
}

extension ConversationImagesViewController: ScreenshotProvider {
    func backgroundScreenshot(for fullscreenController: FullscreenImageViewController) -> UIView? {
        return self.snapshotBackgroundView
    }
}

extension ConversationImagesViewController: AssetCollectionDelegate {
    func assetCollectionDidFetch(collection: ZMCollection, messages: [CategoryMatch: [ZMConversationMessage]], hasMore: Bool) {

        for messageCategory in messages {
            let conversationMessages = messageCategory.value as [ZMConversationMessage]

            if messageCategory.key.including.contains(.image) {
                self.imageMessages.append(contentsOf: conversationMessages)
            }
        }
    }

    func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
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
        return buttonsBar.isHidden && separator.isHidden
    }

    func fadeAndHideMenu(_ hidden: Bool) {
        let duration = 0.3

        showNavigationBarVisible(hidden: hidden, duration: duration)

        buttonsBar.fadeAndHide(hidden, duration: duration)
        separator.fadeAndHide(hidden, duration: duration)
    }

    private func showNavigationBarVisible(hidden: Bool, duration: TimeInterval) {
        guard let view = navigationController?.view else { return }

        UIView.transition(with: view, duration: duration, animations: {
            self.navigationController?.setNavigationBarHidden(hidden, animated: false)
        })
    }

}

extension ConversationImagesViewController {

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    override var previewActionItems: [UIPreviewActionItem] {
        return currentActionController?.previewActionItems ?? []
    }

}

// MARK: - Helper

extension UIView {

    func fadeAndHide(_ hide: Bool, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = UIView.AnimationOptions()) {
        if !hide {
            alpha = 0
            isHidden = false
        }

        let animations = { self.alpha = hide ? 0 : 1 }
        let completion: (Bool) -> Void = { _ in self.isHidden = hide }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(), animations: animations, completion: completion)
    }

}
