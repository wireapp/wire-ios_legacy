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

public protocol CollectionsViewControllerDelegate: class {
    /// NB: only showInConversation and forward actions are forwarded to delegate
    func collectionsViewController(_ viewController: CollectionsViewController, performAction: MessageAction, onMessage: ZMConversationMessage)
}

extension CategoryMatch {
    init(including: ZMCDataModel.MessageCategory, excluding: ZMCDataModel.MessageCategory) {
        self.including = including
        self.excluding = excluding
    }
}

final public class CollectionsViewController: UIViewController {
    public var onDismiss: ((CollectionsViewController)->())?
    public var analyticsTracker: AnalyticsTracker?
    public let sections: CollectionsSectionSet
    public weak var delegate: CollectionsViewControllerDelegate?
    
    fileprivate var contentView: CollectionsView! {
        return self.view as! CollectionsView
    }
    fileprivate let messagePresenter = MessagePresenter()
    
    fileprivate var imageMessages: [ZMConversationMessage] = []
    fileprivate var videoMessages: [ZMConversationMessage] = []
    fileprivate var linkMessages: [ZMConversationMessage] = []
    fileprivate var fileAndAudioMessages: [ZMConversationMessage] = []
    
    fileprivate let collection: AssetCollectionWrapper
    
    fileprivate var fetchingDone: Bool = false {
        didSet {
            if self.isViewLoaded {
                self.updateNoElementsState()
                self.contentView.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    fileprivate var inOverviewMode: Bool {
        return self.sections == .all
    }
    
    convenience init(conversation: ZMConversation) {
        let matchImages = CategoryMatch(including: .image, excluding: .GIF)
        let matchFiles = CategoryMatch(including: .file, excluding: .video)
        let matchVideo = CategoryMatch(including: .video, excluding: .none)
        let matchLink = CategoryMatch(including: .link, excluding: .none)
        
        let holder = AssetCollectionWrapper(conversation: conversation, matchingCategories: [matchImages, matchFiles, matchVideo, matchLink])
        
        self.init(collection: holder)
    }
    
    init(collection: AssetCollectionWrapper, sections: CollectionsSectionSet = .all, messages: [ZMConversationMessage] = [], fetchingDone: Bool = false) {
        self.collection = collection
        self.sections = sections
        
        switch(sections) {
        case CollectionsSectionSet.images:
            self.imageMessages = messages
        case CollectionsSectionSet.filesAndAudio:
            self.fileAndAudioMessages = messages
        case CollectionsSectionSet.videos:
            self.videoMessages = messages
        case CollectionsSectionSet.links:
            self.linkMessages = messages
        default: break
        }
        
        self.fetchingDone = fetchingDone
        
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
        self.view = CollectionsView()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.messagePresenter.targetViewController = self
        self.messagePresenter.modalTargetController = self
        self.messagePresenter.analyticsTracker = self.analyticsTracker

        self.contentView.collectionView.delegate = self
        self.contentView.collectionView.dataSource = self

        self.setupNavigationItem()
        self.updateNoElementsState()
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if self.traitCollection.horizontalSizeClass == .regular {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    override public var shouldAutorotate: Bool {
        if self.traitCollection.horizontalSizeClass == .regular {
            return true
        }
        else {
            return false
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.contentView.collectionViewLayout.invalidateLayout()
        self.contentView.collectionView.reloadData()
    }
    
    override public var prefersStatusBarHidden: Bool {
        return false
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return ColorScheme.default().variant == .dark ? .lightContent : .default
    }
    
    private func updateNoElementsState() {
        // Empty collection contains one element (loading cell)
        if self.fetchingDone && self.inOverviewMode && self.totalNumberOfElements() == 1 {
            self.contentView.noItemsInLibrary = true
        }
    }
    
    private func setupNavigationItem() {
        self.navigationItem.titleView = ConversationTitleView(conversation: self.collection.conversation, interactive: false)
        
        let button = CollectionsView.closeButton()
        button.addTarget(self, action: #selector(CollectionsViewController.closeButtonPressed(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
        if !self.inOverviewMode && self.navigationController?.viewControllers.count > 1 {
            let backButton = CollectionsView.backButton()
            backButton.addTarget(self, action: #selector(CollectionsViewController.backButtonPressed(_:)), for: .touchUpInside)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
    }
    
    public func perform(_ action: MessageAction, for message: ZMConversationMessage, from view: UIView) {
        switch (action) {
        case .cancel:
            ZMUserSession.shared()?.enqueueChanges {
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
    public func assetCollectionDidFetch(collection: ZMCollection, messages: [CategoryMatch : [ZMMessage]], hasMore: Bool) {
        
        for messageCategory in messages {
            let conversationMessages = messageCategory.value as [ZMConversationMessage]
            
            if messageCategory.key.including.contains(.image) {
                self.imageMessages.append(contentsOf: conversationMessages)
            }
            
            if messageCategory.key.including.contains(.file) {
                self.fileAndAudioMessages.append(contentsOf: conversationMessages)
            }
            
            if messageCategory.key.including.contains(.link) {
                self.linkMessages.append(contentsOf: conversationMessages)
            }
            
            if messageCategory.key.including.contains(.video) {
                self.videoMessages.append(contentsOf: conversationMessages)
            }
        }
        
        if self.isViewLoaded {
            self.contentView.collectionView.reloadData()
        }
    }
    
    public func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        self.fetchingDone = true
    }
}

extension CollectionsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    fileprivate func elements(for section: CollectionsSectionSet) -> [ZMConversationMessage] {
        switch(section) {
        case CollectionsSectionSet.images:
            return self.imageMessages
        case CollectionsSectionSet.filesAndAudio:
            return self.fileAndAudioMessages
        case CollectionsSectionSet.videos:
            return self.videoMessages
        case CollectionsSectionSet.links:
            return self.linkMessages
        default: fatal("Unknown section")
        }
    }
    
    fileprivate func numberOfElements(for section: CollectionsSectionSet) -> Int {
        switch(section) {
        case CollectionsSectionSet.images:
            let max = self.inOverviewMode ? self.maxOverviewElementsInGrid : Int.max
            return min(self.imageMessages.count, max)
            
        case CollectionsSectionSet.filesAndAudio:
            let max = self.inOverviewMode ? self.maxOverviewElementsInTable : Int.max
            return min(self.fileAndAudioMessages.count, max)
            
        case CollectionsSectionSet.videos:
            let max = self.inOverviewMode ? self.maxOverviewVideoElementsInTable : Int.max
            return min(self.videoMessages.count, max)
            
        case CollectionsSectionSet.links:
            let max = self.inOverviewMode ? self.maxOverviewElementsInTable : Int.max
            return min(self.linkMessages.count, max)
            
        case CollectionsSectionSet.loading:
            return 1
            
        default: fatal("Unknown section")
        }
    }
    
    fileprivate func totalNumberOfElements() -> Int {
        return CollectionsSectionSet.visible.map { self.numberOfElements(for: $0) }.reduce(0, +)
    }
    
    fileprivate func moreElementsToSee(in section: CollectionsSectionSet) -> Bool {
        return self.elements(for: section).count > self.numberOfElements(for: section)
    }
    
    fileprivate func message(for indexPath: IndexPath) -> ZMConversationMessage {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        
        return self.elements(for: section)[indexPath.row]
    }
    
    fileprivate var girdElementSize: CGSize {
        let size = self.contentView.collectionView.bounds.size.width / CGFloat(self.elementsPerLine)
        
        return CGSize(width: size - 1, height: size - 1)
    }
    
    fileprivate var elementsPerLine: Int {
        var count: Int = 1
        
        repeat {
            count += 1
        } while (self.contentView.collectionView.bounds.size.width / CGFloat(count) > CollectionImageCell.maxCellSize)
        
        return count
    }
    
    fileprivate var maxOverviewElementsInGrid: Int {
        return self.elementsPerLine * 2 // 2 lines of elements
    }
    
    fileprivate var maxOverviewElementsInTable: Int {
        return 2
    }
    
    fileprivate var maxOverviewVideoElementsInTable: Int {
        return 1
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return CollectionsSectionSet.visible.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }
        
        return self.numberOfElements(for: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }
        
        switch(section) {
        case CollectionsSectionSet.images:
            let message = self.message(for: indexPath)

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionImageCell.reuseIdentifier, for: indexPath) as! CollectionImageCell
            cell.message = message
            cell.delegate = self
            cell.desiredWidth = self.girdElementSize.width
            cell.desiredHeight = self.girdElementSize.height
            return cell
        case CollectionsSectionSet.filesAndAudio:
            let message = self.message(for: indexPath)

            if message.fileMessageData!.isAudio() {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionAudioCell.reuseIdentifier, for: indexPath) as! CollectionAudioCell
                cell.message = message
                cell.desiredWidth = collectionView.bounds.size.width
                cell.desiredHeight = .none
                cell.delegate = self
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionFileCell.reuseIdentifier, for: indexPath) as! CollectionFileCell
                cell.message = message
                cell.desiredWidth = collectionView.bounds.size.width
                cell.desiredHeight = .none
                cell.delegate = self
                return cell
            }
        case CollectionsSectionSet.videos:
            let message = self.message(for: indexPath)

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionVideoCell.reuseIdentifier, for: indexPath) as! CollectionVideoCell
            cell.message = message
            cell.desiredWidth = collectionView.bounds.size.width
            cell.desiredHeight = collectionView.bounds.size.width * (3.0 / 4.0)
            cell.delegate = self
            return cell
    
        case CollectionsSectionSet.links:
            let message = self.message(for: indexPath)

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionLinkCell.reuseIdentifier, for: indexPath) as! CollectionLinkCell
            cell.message = message
            cell.delegate = self
            cell.desiredWidth = collectionView.bounds.size.width
            cell.desiredHeight = .none
            return cell
    
        case CollectionsSectionSet.loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionLoadingCell.reuseIdentifier, for: indexPath) as! CollectionLoadingCell
            cell.containerWidth = collectionView.bounds.size.width
            cell.collapsed = self.fetchingDone
            return cell
        
        default: fatal("Unknown section")
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }
        
        if section == CollectionsSectionSet.loading {
            return .zero
        }
        
        return self.elements(for: section).count > 0 ? CGSize(width: collectionView.bounds.size.width, height: 32) : .zero
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
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionHeaderView.reuseIdentifier, for: indexPath) as! CollectionHeaderView
            header.section = section
            header.totalItemsCount = UInt(self.moreElementsToSee(in: section) ? self.elements(for: section).count : 0)
            header.selectionAction = { [weak self] section in
                guard let `self` = self else {
                    return
                }
                let collectionController = CollectionsViewController(collection: self.collection, sections: section, messages: self.elements(for: section), fetchingDone: self.fetchingDone)
                collectionController.analyticsTracker = self.analyticsTracker
                collectionController.onDismiss = self.onDismiss
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

extension CollectionsViewController: CollectionCellDelegate {
    func collectionCell(_ cell: CollectionCell, performAction action: MessageAction) {
        guard let message = cell.message else {
            fatal("Cell does not have a message: \(cell)")
        }
        
        switch action {
        case .forward: fallthrough
        case .showInConversation:
            self.delegate?.collectionsViewController(self, performAction: action, onMessage: message)
        default:
            if Message.isFileTransferMessage(message) {
                self.perform(action, for: message, from: cell)
            }
            else if let linkPreview = message.textMessageData?.linkPreview {
                linkPreview.openableURL?.open()
            }
        }
    }
}
