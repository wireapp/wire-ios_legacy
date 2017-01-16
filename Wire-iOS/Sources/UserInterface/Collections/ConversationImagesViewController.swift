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
import zmessaging

internal final class ConversationImagesViewController: UIPageViewController {
    internal let collection: AssetCollectionWrapper
    fileprivate var imageMessages: [ZMConversationMessage] = []
    internal var currentMessage: ZMConversationMessage {
        didSet {
            self.createNavigationTitle()
        }
    }
    
    public weak var messageActionDelegate: MessageActionResponder? = .none
    
    init(collection: AssetCollectionWrapper, initialMessage: ZMConversationMessage) {
        assert(Message.isImageMessage(initialMessage))
        
        self.collection = collection
        self.currentMessage = initialMessage
        super.init(transitionStyle:.scroll, navigationOrientation:.horizontal, options: [:])
        
        self.delegate = self
        self.dataSource = self
        
        let imagesMatch = CategoryMatch(including: .image, excluding: .GIF)
        
        self.imageMessages = self.collection.assetCollection.assets(for: imagesMatch)
        self.collection.assetCollectionDelegate.add(self)
        
        self.createNavigationTitle()
        
        self.setViewControllers([self.imageController(for: self.currentMessage)], direction: .forward, animated: false, completion: .none)
    }
    
    deinit {
        self.collection.assetCollectionDelegate.remove(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func imageController(for message: ZMConversationMessage) -> FullscreenImageViewController {
        let imageViewController = FullscreenImageViewController(message: message)
        imageViewController.delegate = self
        imageViewController.swipeToDismiss = false
        return imageViewController
    }
    
    private func createNavigationTitle() {
        guard let sender = currentMessage.sender, let serverTimestamp = currentMessage.serverTimestamp else {
            return
        }
        self.navigationItem.titleView = TwoLineTitleView(first: sender.displayName.uppercased(), second: serverTimestamp.wr_formattedDate())
    }
    
    var currentController: FullscreenImageViewController {
        get {
            guard let imageController = viewControllers?.first as? FullscreenImageViewController else {
                fatal("No first controller")
            }
            
            return imageController
        }
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
        
        guard let messageIndex = self.imageMessages.index(where: { (message: ZMConversationMessage) -> (Bool) in
            message.hash == imageController.message.hash
        }) else {
            fatal("Unknown message \(imageController.message)")
        }

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
        
        guard let messageIndex = self.imageMessages.index(where: { (message: ZMConversationMessage) -> (Bool) in
            message.hash == imageController.message.hash
        }) else {
            fatal("Unknown message \(imageController.message)")
        }
        
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
