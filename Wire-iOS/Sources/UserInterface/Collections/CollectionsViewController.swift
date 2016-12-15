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
    public var analyticsTracker: AnalyticsTracker?
    
    private let collectionsView = CollectionsView()
    fileprivate let messagePresenter = MessagePresenter()
    
    fileprivate var imageMessages: [ZMConversationMessage] = []
    fileprivate var videoMessages: [ZMConversationMessage] = []
    fileprivate var fileAndAudioMessages: [ZMConversationMessage] = []
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init(nibName: .none, bundle: .none)
        
        self.imageMessages = self.conversation.messages.filter {
            if let message = $0 as? ZMConversationMessage, let _ = message.imageMessageData
            { return true }
            else
            { return false }
        } as! [ZMConversationMessage]
        
        self.videoMessages = self.conversation.messages.filter {
            if let message = $0 as? ZMConversationMessage, let fileMessageData = message.fileMessageData, fileMessageData.isVideo()
            { return true }
            else
            { return false }
        } as! [ZMConversationMessage]
        
        self.fileAndAudioMessages = self.conversation.messages.filter {
            if let message = $0 as? ZMConversationMessage, let fileMessageData = message.fileMessageData, !fileMessageData.isVideo()
            { return true }
            else
            { return false }
            } as! [ZMConversationMessage]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        self.messagePresenter.targetViewController = self
        self.messagePresenter.modalTargetController = self
        self.messagePresenter.analyticsTracker = self.analyticsTracker
        
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
    
    enum CollectionsSection: UInt {
        case images = 0
        case filesAndAudio = 1
        case videos = 2
        
        static func total() -> UInt {
            return CollectionsSection.videos.rawValue + 1
        }
    }
    
    private func message(for indexPath: IndexPath) -> ZMConversationMessage {
        guard let section = CollectionsSection(rawValue: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }

        switch(section) {
        case .images:
            return self.imageMessages[indexPath.item]
        case .filesAndAudio:
            return self.fileAndAudioMessages[indexPath.item]
        case .videos:
            return self.videoMessages[indexPath.item]
        }
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Int(CollectionsSection.total())
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = CollectionsSection(rawValue: UInt(section)) else {
            fatal("Unknown section")
        }
        
        switch(section) {
        case .images:
            return self.imageMessages.count
        case .filesAndAudio:
            return self.fileAndAudioMessages.count
        case .videos:
            return self.videoMessages.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = CollectionsSection(rawValue: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        
        let message = self.message(for: indexPath)
        
        switch(section) {
        case .images:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionImageCell.reuseIdentifier, for: indexPath) as! CollectionImageCell
            cell.message = message
            return cell
        case .filesAndAudio:
            if message.fileMessageData!.isAudio() {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionAudioCell.reuseIdentifier, for: indexPath) as! CollectionAudioCell
                cell.message = message
                cell.delegate = self
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionFileCell.reuseIdentifier, for: indexPath) as! CollectionFileCell
                cell.message = message
                cell.delegate = self
                return cell
            }
        case .videos:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionVideoCell.reuseIdentifier, for: indexPath) as! CollectionVideoCell
            cell.message = message
            cell.delegate = self
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = CollectionsSection(rawValue: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        switch(section) {
        case .images:
            var divider = 1
            
            repeat {
                divider += 1
            } while (collectionView.bounds.size.width / CGFloat(divider) > CollectionImageCell.cellSize)
            
            let size = collectionView.bounds.size.width / CGFloat(divider)
            
            return CGSize(width: size, height: size)
            
        case .filesAndAudio:
            return CGSize(width: collectionView.bounds.size.width, height: 56)
        case .videos:
            return CGSize(width: collectionView.bounds.size.width, height: (collectionView.bounds.size.width / 4) * 3)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let message = self.message(for: indexPath)
       
        let conversations = SessionObjectCache.shared().allConversations.shareableConversations(excluding: message.conversation!)
        
        let shareViewController: ShareViewController<ZMConversation, ZMMessage> = ShareViewController(shareable: message as! ZMMessage, destinations: conversations)
        
        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>) -> () in
            shareController.presentingViewController?.dismiss(animated: true) {
            }
        }
        
        self.present(shareViewController, animated: true, completion: .none)        
    }
}

extension CollectionsViewController: TransferViewDelegate {
    public func transferView(_ view: TransferView, didSelect action: MessageAction) {
        switch (action) {
        case .cancel:
            ZMUserSession.shared().enqueueChanges {
                view.fileMessage?.fileMessageData?.cancelTransfer()
            }
        case .present:
            guard let targetView = view as? UIView, let message = view.fileMessage else {
                return
            }
            self.messagePresenter.open(message, targetView: targetView)
            
        default:
            break
        }
    }
}
