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
import Cartography
import zmessaging

typealias DismissAction = (_ completion: (()->())?)->()

internal final class ConversationImagesViewController: UIViewController {
    internal let collection: AssetCollectionWrapper
    public var swipeToDismiss: Bool = false
    public var dismissAction: DismissAction? = .none
    public var snapshotBackgroundView: UIView? = .none
    fileprivate var imageMessages: [ZMConversationMessage] = []
    internal var currentMessage: ZMConversationMessage {
        didSet {
            self.createNavigationTitle()
        }
    }
    internal var pageViewController: UIPageViewController!
    internal var buttonsBar: InputBarButtonsView!
    internal let overlay = FeedbackOverlayView()
    internal let separator = UIView()
    
    internal let inverse: Bool
    
    public weak var messageActionDelegate: MessageActionResponder? = .none
    
    init(collection: AssetCollectionWrapper, initialMessage: ZMConversationMessage, inverse: Bool = false) {
        assert(Message.isImageMessage(initialMessage))
        
        self.inverse = inverse
        self.collection = collection
        self.currentMessage = initialMessage

        super.init(nibName: .none, bundle: .none)
        let imagesMatch = CategoryMatch(including: .image, excluding: .GIF)
        
        self.imageMessages = self.collection.assetCollection.assets(for: imagesMatch)
        self.collection.assetCollectionDelegate.add(self)
        
        self.createNavigationTitle()

        separator.cas_styleClass = "separator"
    }
    
    deinit {
        self.collection.assetCollectionDelegate.remove(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createPageController()
        self.createControlsBar()
        view.addSubview(overlay)
        view.addSubview(separator)
        
        constrain(self.view, self.pageViewController.view, self.buttonsBar, overlay, separator) { view, pageControllerView, buttonsBar, overlay, separator in
            pageControllerView.top == view.top
            pageControllerView.leading == view.leading
            pageControllerView.trailing == view.trailing
            
            pageControllerView.bottom == buttonsBar.top
            
            buttonsBar.leading == view.leading
            buttonsBar.trailing == view.trailing
            buttonsBar.bottom == view.bottom
            buttonsBar.height == 84

            overlay.edges == buttonsBar.edges

            separator.height == .hairline
            separator.top == buttonsBar.top
            separator.leading == buttonsBar.leading
            separator.trailing == buttonsBar.trailing
        }
    }
    
    override open var prefersStatusBarHidden: Bool {
        return false
    }
    
    private func createPageController() {
        self.pageViewController = UIPageViewController(transitionStyle:.scroll, navigationOrientation:.horizontal, options: [:])
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        self.pageViewController.setViewControllers([self.imageController(for: self.currentMessage)], direction: .forward, animated: false, completion: .none)
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
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
    
    private func createControlsBar() {
        let copyButton = IconButton.iconButtonDefault()
        copyButton.setIcon(.copy, with: .tiny, for: .normal)
        copyButton.accessibilityLabel = "copy"
        copyButton.addTarget(self, action: #selector(ConversationImagesViewController.copyCurrent(_:)), for: .touchUpInside)
        
        let saveButton = IconButton.iconButtonDefault()
        saveButton.setIcon(.save, with: .tiny, for: .normal)
        saveButton.accessibilityLabel = "save"
        saveButton.addTarget(self, action: #selector(ConversationImagesViewController.saveCurrent(_:)), for: .touchUpInside)
        
        let shareButton = IconButton.iconButtonDefault()
        shareButton.setIcon(.export, with: .tiny, for: .normal)
        shareButton.accessibilityLabel = "share"
        shareButton.addTarget(self, action: #selector(ConversationImagesViewController.shareCurrent(_:)), for: .touchUpInside)
        
        let revealButton = IconButton.iconButtonDefault()
        revealButton.setIcon(.eye, with: .tiny, for: .normal)
        revealButton.accessibilityLabel = "reveal in conversation"
        revealButton.addTarget(self, action: #selector(ConversationImagesViewController.revealCurrent(_:)), for: .touchUpInside)
        
        self.buttonsBar = InputBarButtonsView(buttons: [copyButton, saveButton, shareButton, revealButton])
        self.view.addSubview(self.buttonsBar)
    }
    
    fileprivate func imageController(for message: ZMConversationMessage) -> FullscreenImageViewController {
        let imageViewController = FullscreenImageViewController(message: message)
        imageViewController.delegate = self
        imageViewController.swipeToDismiss = self.swipeToDismiss
        imageViewController.showCloseButton = false
        if let snapshotBackgroundView = self.snapshotBackgroundView {
            let innerSnapshot = UIView()
            innerSnapshot.addSubview(snapshotBackgroundView)
            let topInset: CGFloat = -64
            
            constrain(innerSnapshot, snapshotBackgroundView) { innerSnapshot, snapshotBackgroundView in
                snapshotBackgroundView.leading == innerSnapshot.leading
                snapshotBackgroundView.top == innerSnapshot.top + topInset
                snapshotBackgroundView.trailing == innerSnapshot.trailing
                snapshotBackgroundView.bottom == innerSnapshot.bottom + topInset
            }
            imageViewController.snapshotBackgroundView = innerSnapshot
        }
        imageViewController.dismissAction = self.dismissAction
        return imageViewController
    }
    
    fileprivate func indexOf(message messageToFind: ZMConversationMessage) -> Int? {
        guard let messageToFind = messageToFind as? ZMMessage else {
            return .none
        }
        return self.imageMessages.index(where: { (message: ZMConversationMessage) -> (Bool) in
            guard let message = message as? ZMMessage else {
                return false
            }
            return message == messageToFind
        })
    }
    
    private func createNavigationTitle() {
        guard let sender = currentMessage.sender, let serverTimestamp = currentMessage.serverTimestamp else {
            return
        }
        self.navigationItem.titleView = TwoLineTitleView(first: sender.displayName.uppercased(), second: serverTimestamp.wr_formattedDate())
    }
    
    var currentController: FullscreenImageViewController {
        get {
            guard let imageController = self.pageViewController.viewControllers?.first as? FullscreenImageViewController else {
                fatal("No first controller")
            }
            
            return imageController
        }
    }
    
    @objc public func copyCurrent(_ sender: AnyObject!) {
        let text = "collections.image_viewer.copied.title".localized.uppercased()
        overlay.show(text: text)
        self.messageActionDelegate?.wants(toPerform: .copy, for: self.currentMessage)
    }
    
    @objc public func saveCurrent(_ sender: UIButton!) {
        self.currentController.performSaveImageAnimation(from: sender)
        self.messageActionDelegate?.wants(toPerform: .save, for: self.currentMessage)
    }
    
    @objc public func shareCurrent(_ sender: AnyObject!) {
        self.messageActionDelegate?.wants(toPerform: .forward, for: self.currentMessage)
    }
    
    @objc public func revealCurrent(_ sender: AnyObject!) {
        self.messageActionDelegate?.wants(toPerform: .showInConversation, for: self.currentMessage)
    }
}

extension ConversationImagesViewController: MessageActionResponder {
    public func canPerform(_ action: MessageAction, for message: ZMConversationMessage!) -> Bool {
        return self.messageActionDelegate?.canPerform(action, for: message) ?? false
    }

    func wants(toPerform action: MessageAction, for message: ZMConversationMessage!) {
        self.messageActionDelegate?.wants(toPerform: action, for: message)
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
        if finished && completed {
            self.currentMessage = self.currentController.message
        }
    }
}
