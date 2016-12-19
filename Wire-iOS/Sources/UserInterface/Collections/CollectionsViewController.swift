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
import ZMCDataModel

final public class CollectionsViewController: UIViewController {
    public var onDismiss: ((CollectionsViewController)->())?
    public var analyticsTracker: AnalyticsTracker?
    public let sections: CollectionsSectionSet
    
    fileprivate let collectionsView = CollectionsView()
    fileprivate let messagePresenter = MessagePresenter()
    
    fileprivate var imageMessages: [ZMConversationMessage] = []
    fileprivate var videoMessages: [ZMConversationMessage] = []
    fileprivate var fileAndAudioMessages: [ZMConversationMessage] = []
    
    fileprivate let collection: AssetCollectionHolder
    
    convenience init(conversation: ZMConversation) {
        
        let assetCollecitonMulticastDelegate = AssetCollectionMulticastDelegate()
        
        let include = [MessageCategory.image, MessageCategory.file]
        let exclude = [MessageCategory.GIF, MessageCategory.video]
        
        let assetCollection = AssetCollection(conversation: conversation, including: include, excluding: exclude, delegate: assetCollecitonMulticastDelegate)
        
        let holder = AssetCollectionHolder(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: assetCollecitonMulticastDelegate)
        
        self.init(collection: holder)
    }
    
    init(collection: AssetCollectionHolder, sections: CollectionsSectionSet = .all, messages: [ZMConversationMessage] = []) {
        self.collection = collection
        self.sections = sections
        
        switch(sections) {
        case CollectionsSectionSet.images:
            self.imageMessages = messages
        case CollectionsSectionSet.filesAndAudio:
            self.fileAndAudioMessages = messages
        case CollectionsSectionSet.videos:
            self.videoMessages = messages
        default: break
        }
        
        super.init(nibName: .none, bundle: .none)
        self.collection.assetCollectionDelegate.add(self)
    }
    
    deinit {
        self.collection.assetCollectionDelegate.remove(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        self.view = self.collectionsView
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.messagePresenter.targetViewController = self
        self.messagePresenter.modalTargetController = self
        self.messagePresenter.analyticsTracker = self.analyticsTracker

        self.collectionsView.collectionView.delegate = self
        self.collectionsView.collectionView.dataSource = self

        self.setupNavigationItem()
    }
    
    private func setupNavigationItem() {
        self.navigationItem.titleView = ConversationTitleView(conversation: self.collection.conversation, interactive: false)
        
        let button = CollectionsView.closeButton()
        button.addTarget(self, action: #selector(CollectionsViewController.closeButtonPressed(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
        if self.navigationController?.viewControllers.count > 1 {
            let backButton = CollectionsView.backButton()
            backButton.addTarget(self, action: #selector(CollectionsViewController.backButtonPressed(_:)), for: .touchUpInside)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        switch ColorScheme.default().variant {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }
    
    public func perform(_ action: MessageAction, for message: ZMConversationMessage, from view: UIView) {
        switch (action) {
        case .cancel:
            ZMUserSession.shared().enqueueChanges {
                message.fileMessageData?.cancelTransfer()
            }
        case .present:
            self.messagePresenter.open(message, targetView: view)
            
        default:
            break
        }
    }
    
    @objc func closeButtonPressed(_ button: UIButton) {
        self.onDismiss?(self)
    }
    
    @objc func backButtonPressed(_ button: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}

extension CollectionsViewController: AssetCollectionDelegate {
    public func assetCollectionDidFetch(collection: ZMCollection, messages: [MessageCategory : [ZMMessage]], hasMore: Bool) {
        for messageCategory in messages {
            let conversationMessages = messageCategory.value as [ZMConversationMessage]
            
            if messageCategory.key.contains(.image) {
                self.imageMessages.append(contentsOf: conversationMessages)
            }
            
            if messageCategory.key.contains(.file) {
                self.fileAndAudioMessages.append(contentsOf: conversationMessages)
            }
        }
        
        self.collectionsView.collectionView.reloadData()
    }
    
    public func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        
    }
}

extension CollectionsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private func elements(for section: CollectionsSectionSet) -> [ZMConversationMessage] {
        switch(section) {
        case CollectionsSectionSet.images:
            return self.imageMessages
        case CollectionsSectionSet.filesAndAudio:
            return self.fileAndAudioMessages
        case CollectionsSectionSet.videos:
            return self.videoMessages
        default: fatal("Unknown section")
        }
    }
    
    private func message(for indexPath: IndexPath) -> ZMConversationMessage {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        
        return self.elements(for: section)[indexPath.row]
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Int(CollectionsSectionSet.totalVisible())
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }
        
        switch(section) {
        case CollectionsSectionSet.images:
            return self.imageMessages.count
        case CollectionsSectionSet.filesAndAudio:
            return self.fileAndAudioMessages.count
        case CollectionsSectionSet.videos:
            return self.videoMessages.count
        default: fatal("Unknown section")
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        
        let message = self.message(for: indexPath)
        
        switch(section) {
        case CollectionsSectionSet.images:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionImageCell.reuseIdentifier, for: indexPath) as! CollectionImageCell
            cell.message = message
            return cell
        case CollectionsSectionSet.filesAndAudio:
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
        case CollectionsSectionSet.videos:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionVideoCell.reuseIdentifier, for: indexPath) as! CollectionVideoCell
            cell.message = message
            cell.delegate = self
            return cell
        default: fatal("Unknown section")
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        switch(section) {
        case CollectionsSectionSet.images:
            var divider = 1
            
            repeat {
                divider += 1
            } while (collectionView.bounds.size.width / CGFloat(divider) > CollectionImageCell.cellSize)
            
            let size = collectionView.bounds.size.width / CGFloat(divider)
            
            return CGSize(width: size - 1, height: size - 1)
            
        case CollectionsSectionSet.filesAndAudio:
            return CGSize(width: collectionView.bounds.size.width, height: 64)
        case CollectionsSectionSet.videos:
            return CGSize(width: collectionView.bounds.size.width, height: (collectionView.bounds.size.width / 4) * 3)
        default: fatal("Unknown section")
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }
        
        return self.elements(for: section).count > 0 ? CGSize(width: collectionView.bounds.size.width, height: 28) : .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        
        switch (kind) {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionsHeaderView.reuseIdentifier, for: indexPath) as! CollectionsHeaderView
            header.section = section
            header.showActionButton = self.sections == .all
            header.selectionAction = { [weak self] section in
                guard let `self` = self else {
                    return
                }
                let collectionController = CollectionsViewController(collection: self.collection, sections: section, messages: self.elements(for: section))
                collectionController.analyticsTracker = self.analyticsTracker
                collectionController.onDismiss = {
                    _ = $0.navigationController?.popViewController(animated: true)
                }
                self.navigationController?.pushViewController(collectionController, animated: true)
            }
            return header
        default:
            fatal("No supplementary view for \(kind)")
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let message = self.message(for: indexPath)
        self.perform(.present, for: message, from: collectionView.cellForItem(at: indexPath)!)
    }
}

extension CollectionsViewController: TransferViewDelegate {
    public func transferView(_ view: TransferView, didSelect action: MessageAction) {
        guard let targetView = view as? UIView else {
            return
        }
        self.perform(action, for: view.fileMessage!, from: targetView)
    }
}
