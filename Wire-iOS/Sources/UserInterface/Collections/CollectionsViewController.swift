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


final public class CollectionsViewController: UIViewController {
    public let conversation: ZMConversation
    public var onDismiss: ((CollectionsViewController)->())?

    private let collectionsView = CollectionsView()
    fileprivate var imageMessages: [ZMConversationMessage] = []
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init(nibName: .none, bundle: .none)
        
        self.imageMessages = self.conversation.messages.flatMap {
            if let message = $0 as? ZMConversationMessage, let _ = message.imageMessageData {
                return message
            }
            else {
                return .none
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        self.view = self.collectionsView
        
        self.collectionsView.collectionView.delegate = self
        self.collectionsView.collectionView.dataSource = self
        self.navigationItem.titleView = ConversationTitleView(conversation: self.conversation)
        
        
        let button = IconButton.iconButtonDefault()
        button.setIcon(.X, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        button.addTarget(self, action: #selector(CollectionsViewController.closeButtonPressed(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = "close"
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -16)
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.collectionsView.navigationBar.pushItem(self.navigationItem, animated: false)
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        switch ColorScheme.default().variant {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }
    
    @objc func closeButtonPressed(_ button: UIButton) {
        self.onDismiss?(self)
    }
}

extension CollectionsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageMessages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionImageCell.reuseIdentifier, for: indexPath) as! CollectionImageCell
        cell.message = self.imageMessages[indexPath.item]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var divider = 1
        
        repeat {
            divider += 1
        } while (collectionView.bounds.size.width / CGFloat(divider) > CollectionImageCell.cellSize)
        
        let size = collectionView.bounds.size.width / CGFloat(divider)
        
        return CGSize(width: size, height: size)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let message = self.imageMessages[indexPath.item]
        
        let conversations = SessionObjectCache.shared().allConversations.shareableConversations(excluding: message.conversation!)
        
        let shareViewController: ShareViewController<ZMConversation, ZMMessage> = ShareViewController(shareable: message as! ZMMessage, destinations: conversations)
        
        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>) -> () in
            shareController.presentingViewController?.dismiss(animated: true) {
            }
        }
        
        self.present(shareViewController, animated: true, completion: .none)        
    }
}
