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

public struct CollectionsSectionSet: OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init?(index: UInt) {
        self = type(of: self).visible[Int(index)]
    }
    
    public static let none = CollectionsSectionSet(rawValue: 0)
    public static let images = CollectionsSectionSet(rawValue: 1)
    public static let filesAndAudio = CollectionsSectionSet(rawValue: 1 << 1)
    public static let videos = CollectionsSectionSet(rawValue: 1 << 2)
    public static let links = CollectionsSectionSet(rawValue: 1 << 3)
    
    public static let all: CollectionsSectionSet = [.images, .filesAndAudio, .videos, .links]
    
    public static let visible: [CollectionsSectionSet] = [images, filesAndAudio, videos] // links
    
    static func totalVisible() -> UInt {
        return UInt(self.visible.count)
    }
}

final public class CollectionsViewController: UIViewController {
    public let conversation: ZMConversation
    public var onDismiss: ((CollectionsViewController)->())?
    public var analyticsTracker: AnalyticsTracker?
    public let sections: CollectionsSectionSet
    
    private let collectionsView = CollectionsView()
    fileprivate let messagePresenter = MessagePresenter()
    
    fileprivate var imageMessages: [ZMConversationMessage] = []
    fileprivate var videoMessages: [ZMConversationMessage] = []
    fileprivate var fileAndAudioMessages: [ZMConversationMessage] = []
    
    init(conversation: ZMConversation, sections: CollectionsSectionSet = .all) {
        self.conversation = conversation
        self.sections = sections
        super.init(nibName: .none, bundle: .none)
        
        if sections.contains(.images) {
            self.imageMessages = self.conversation.messages.filter {
                if let message = $0 as? ZMConversationMessage, let _ = message.imageMessageData
                { return true }
                else
                { return false }
            } as! [ZMConversationMessage]
        }
        
        if sections.contains(.videos) {
            self.videoMessages = self.conversation.messages.filter {
                if let message = $0 as? ZMConversationMessage, let fileMessageData = message.fileMessageData, fileMessageData.isVideo()
                { return true }
                else
                { return false }
                } as! [ZMConversationMessage]
        }
        
        if sections.contains(.filesAndAudio) {
            self.fileAndAudioMessages = self.conversation.messages.filter {
                if let message = $0 as? ZMConversationMessage, let fileMessageData = message.fileMessageData, !fileMessageData.isVideo()
                { return true }
                else
                { return false }
                } as! [ZMConversationMessage]
        }
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
        self.navigationItem.titleView = ConversationTitleView(conversation: self.conversation, interactive: false)
        
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
                let collectionController = CollectionsViewController(conversation: self.conversation, sections: section)
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
