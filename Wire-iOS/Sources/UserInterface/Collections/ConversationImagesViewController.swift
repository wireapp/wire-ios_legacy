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
import Cartography
import zmessaging

internal final class ConversationImagesViewController: UIViewController {
    internal let collection: AssetCollectionWrapper
    fileprivate var imageMessages: [ZMConversationMessage] = []
    internal var currentMessage: ZMConversationMessage {
        didSet {
            self.createNavigationTitle()
        }
    }
    internal var pageViewController: UIPageViewController!
    internal var buttonsBar: InputBarButtonsView!
    
    public weak var messageActionDelegate: MessageActionResponder? = .none
    
    init(collection: AssetCollectionWrapper, initialMessage: ZMConversationMessage) {
        assert(Message.isImageMessage(initialMessage))
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createPageController()
        self.createControlsBar()
        
        constrain(self.view, self.pageViewController.view, self.buttonsBar) { view, pageControllerView, buttonsBar in
            pageControllerView.top == view.top
            pageControllerView.leading == view.leading
            pageControllerView.trailing == view.trailing
            
            pageControllerView.bottom == buttonsBar.top
            
            buttonsBar.leading == view.leading
            buttonsBar.trailing == view.trailing
            buttonsBar.bottom == view.bottom
            buttonsBar.height == 84
        }
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
    
    private func createControlsBar() {
        let copyButton = IconButton.iconButtonDefault()
        copyButton.setIcon(.copy, with: .tiny, for: .normal)
        copyButton.addTarget(self, action: #selector(ConversationImagesViewController.copyCurrent(_:)), for: .touchUpInside)
        
        let saveButton = IconButton.iconButtonDefault()
        saveButton.setIcon(.save, with: .tiny, for: .normal)
        saveButton.addTarget(self, action: #selector(ConversationImagesViewController.saveCurrent(_:)), for: .touchUpInside)
        
        let shareButton = IconButton.iconButtonDefault()
        shareButton.setIcon(.export, with: .tiny, for: .normal)
        shareButton.addTarget(self, action: #selector(ConversationImagesViewController.shareCurrent(_:)), for: .touchUpInside)
        
        let revealButton = IconButton.iconButtonDefault()
        revealButton.setIcon(.eye, with: .tiny, for: .normal)
        revealButton.addTarget(self, action: #selector(ConversationImagesViewController.revealCurrent(_:)), for: .touchUpInside)
        
        self.buttonsBar = InputBarButtonsView(buttons: [copyButton, saveButton, shareButton, revealButton])
        self.view.addSubview(self.buttonsBar)
    }
    
    fileprivate func imageController(for message: ZMConversationMessage) -> FullscreenImageViewController {
        let imageViewController = FullscreenImageViewController(message: message)
        imageViewController.delegate = self
        imageViewController.swipeToDismiss = false
        imageViewController.showCloseButton = false
        return imageViewController
    }
    
    fileprivate func indexOf(message messageToFind: ZMConversationMessage) -> Int {
        return self.imageMessages.index(where: { (message: ZMConversationMessage) -> (Bool) in
            (message as! ZMMessage) == (messageToFind as! ZMMessage)
        })!
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
        
        let messageIndex = self.indexOf(message: imageController.message)
        
        let nextIndex = messageIndex + 1
        guard self.imageMessages.count > nextIndex else {
            return .none
        }
        
        return self.imageController(for: self.imageMessages[nextIndex])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? FullscreenImageViewController else {
            fatal("Unknown controller \(viewController)")
        }
        
        let messageIndex = self.indexOf(message: imageController.message)
        
        let nextIndex = messageIndex - 1
        guard nextIndex >= 0 else {
            return .none
        }
        
        return self.imageController(for: self.imageMessages[nextIndex])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed {
            self.currentMessage = self.currentController.message
        }
    }
}
