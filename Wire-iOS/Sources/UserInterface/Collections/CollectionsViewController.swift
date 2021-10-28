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

import UIKit
import WireSyncEngine

protocol CollectionsViewControllerDelegate: class {
    func collectionsViewController(_ viewController: CollectionsViewController, performAction: MessageAction, onMessage: ZMConversationMessage)
}

final class CollectionsViewController: UIViewController {
    var onDismiss: ((CollectionsViewController) -> Void)?
    let sections: CollectionsSectionSet
    weak var delegate: CollectionsViewControllerDelegate?
    var isShowingSearchResults: Bool {
        return !textSearchController.resultsView.isHidden
    }

    var shouldTrackOnNextOpen = false

    var currentTextSearchQuery: [String] {
        return textSearchController.searchQuery?.components(separatedBy: .whitespacesAndNewlines) ?? []
    }

    fileprivate var contentView: CollectionsView! {
        return view as? CollectionsView
    }
    fileprivate let messagePresenter = MessagePresenter()
    fileprivate weak var selectedMessage: ZMConversationMessage? = .none

    fileprivate var imageMessages: [ZMConversationMessage] = []
    fileprivate var videoMessages: [ZMConversationMessage] = []
    fileprivate var linkMessages: [ZMConversationMessage] = []
    fileprivate var fileAndAudioMessages: [ZMConversationMessage] = []

    fileprivate var collection: AssetCollectionWrapper!

    fileprivate var lastLayoutSize: CGSize = .zero
    fileprivate var deletionDialogPresenter: DeletionDialogPresenter?

    fileprivate var fetchingDone: Bool = false {
        didSet {
            if isViewLoaded {
                updateNoElementsState()
                contentView.collectionView.reloadData()
            }

            trackOpeningIfNeeded()
        }
    }

    fileprivate var inOverviewMode: Bool {
        return sections == .all
    }

    fileprivate lazy var textSearchController: TextSearchViewController =  TextSearchViewController(conversation: collection.conversation)

    convenience init(conversation: ZMConversation) {
        let matchImages = CategoryMatch(including: .image, excluding: .GIF)
        let matchFiles = CategoryMatch(including: .file, excluding: .video)
        let matchVideo = CategoryMatch(including: .video, excluding: .none)
        let matchLink = CategoryMatch(including: .linkPreview, excluding: .none)

        let holder = AssetCollectionWrapper(conversation: conversation, matchingCategories: [matchImages, matchFiles, matchVideo, matchLink])

        self.init(collection: holder)
    }

    init(collection: AssetCollectionWrapper, sections: CollectionsSectionSet = .all, messages: [ZMConversationMessage] = [], fetchingDone: Bool = false) {
        self.collection = collection
        self.sections = sections

        switch sections {
        case CollectionsSectionSet.images:
            imageMessages = messages
        case CollectionsSectionSet.filesAndAudio:
            fileAndAudioMessages = messages
        case CollectionsSectionSet.videos:
            videoMessages = messages
        case CollectionsSectionSet.links:
            linkMessages = messages
        default: break
        }

        self.fetchingDone = fetchingDone

        super.init(nibName: .none, bundle: .none)
        collection.assetCollectionDelegate.add(self)
        deletionDialogPresenter = DeletionDialogPresenter(sourceViewController: self)
    }

    deinit {
        collection.assetCollectionDelegate.remove(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refetchCollection() {
        collection.assetCollectionDelegate.remove(self)
        imageMessages = []
        videoMessages = []
        linkMessages = []
        fileAndAudioMessages = []
        collection = AssetCollectionWrapper(conversation: collection.conversation, matchingCategories: collection.matchingCategories)
        collection.assetCollectionDelegate.add(self)
        contentView.collectionView.reloadData()
    }

    override func loadView() {
        view = CollectionsView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textSearchController.delegate = self
        contentView.constrainViews(searchViewController: textSearchController)

        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = self

        contentView.collectionView.delegate = self
        contentView.collectionView.dataSource = self
        contentView.collectionView.prefetchDataSource = self

        updateNoElementsState()

        NotificationCenter.default.addObserver(forName: .featureConfigDidChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let featureUpdateEvent = note.object as? FeatureUpdateEventPayload,
                  featureUpdateEvent.name == .fileSharing else {
                return
            }
            self?.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationItem()
        flushLayout()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        /// Prevent content overlaps navi bar
        navigationController?.navigationBar.isTranslucent = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textSearchController.teardown()
    }

    // MARK: - device orientation

    /// Notice: for iPad with iOS9 in landscape mode, horizontalSizeClass is .unspecified (.regular in iOS11).
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    override var shouldAutorotate: Bool {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            return false
        default:
            return true
        }
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    private func flushLayout() {
        for cell in contentView.collectionView.visibleCells {
            guard let cell = cell as? CollectionCell else {
                continue
            }

            cell.flushCachedSize()
        }

        contentView.collectionViewLayout.invalidateLayout()
        contentView.collectionViewLayout.finalizeCollectionViewUpdates()
    }

    private func trackOpeningIfNeeded() {
        guard shouldTrackOnNextOpen && fetchingDone else { return }

        shouldTrackOnNextOpen = false
    }

    @objc
    private func reloadData() {
        UIView.performWithoutAnimation {
            contentView.collectionView.performBatchUpdates({
                for section in [CollectionsSectionSet.images, CollectionsSectionSet.videos] {
                    if numberOfElements(for: section) != 0 {
                        contentView.collectionView.reloadSections(IndexSet(integer: (CollectionsSectionSet.visible.firstIndex(of: section))!))
                    }
                }
            }) { _ in
                self.contentView.collectionView.reloadData()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if lastLayoutSize != view.bounds.size {
            lastLayoutSize = view.bounds.size

            DispatchQueue.main.async {
                self.flushLayout()
                self.reloadData()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackOpeningIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard view.window != nil else {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.flushLayout()
        }) { _ in
            self.reloadData()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    fileprivate func updateNoElementsState() {
        contentView.noItemsInLibrary = fetchingDone && inOverviewMode && totalNumberOfElements() == 0
    }

    private func setupNavigationItem() {

        // The label must be inset from the top due to navigation bar title alignment
        let titleViewWrapper = UIView()
        let titleView = ConversationTitleView(conversation: collection.conversation, interactive: false)
        titleViewWrapper.addSubview(titleView)

        [titleView, titleViewWrapper].prepareForLayout()
        NSLayoutConstraint.activate([
          titleView.topAnchor.constraint(equalTo: titleViewWrapper.topAnchor, constant: 4),
          titleView.leftAnchor.constraint(equalTo: titleViewWrapper.leftAnchor),
          titleView.rightAnchor.constraint(equalTo: titleViewWrapper.rightAnchor),
          titleView.bottomAnchor.constraint(equalTo: titleViewWrapper.bottomAnchor)
        ])

        titleViewWrapper.setNeedsLayout()

        let size = titleViewWrapper.systemLayoutSizeFitting(CGSize(width: 320, height: 44))
        titleViewWrapper.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        navigationItem.titleView = titleViewWrapper

        let button = CollectionsView.closeButton()
        button.addTarget(self, action: #selector(CollectionsViewController.closeButtonPressed(_:)), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)

        if !inOverviewMode && navigationController?.viewControllers.count > 1 {
            let backButton = CollectionsView.backButton()
            backButton.addTarget(self, action: #selector(CollectionsViewController.backButtonPressed(_:)), for: .touchUpInside)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
    }

    @objc
    fileprivate func closeButtonPressed(_ button: UIButton) {
        onDismiss?(self)
    }

    @objc
    fileprivate func backButtonPressed(_ button: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

extension CollectionsViewController: AssetCollectionDelegate {
    func assetCollectionDidFetch(collection: ZMCollection, messages: [CategoryMatch: [ZMConversationMessage]], hasMore: Bool) {

        for messageCategory in messages {
            let conversationMessages = messageCategory.value

            if messageCategory.key.including.contains(.image) {
                imageMessages.append(contentsOf: conversationMessages)
            }

            if messageCategory.key.including.contains(.file) {
                fileAndAudioMessages.append(contentsOf: conversationMessages)
            }

            if messageCategory.key.including.contains(.linkPreview) {
                linkMessages.append(contentsOf: conversationMessages)
            }

            if messageCategory.key.including.contains(.video) {
                videoMessages.append(contentsOf: conversationMessages)
            }
        }

        if isViewLoaded {
            updateNoElementsState()
            contentView.collectionView.reloadData()
        }
    }

    func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        fetchingDone = true
    }
}

extension CollectionsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    fileprivate func elements(for section: CollectionsSectionSet) -> [ZMConversationMessage] {
        switch section {
        case CollectionsSectionSet.images:
            return imageMessages
        case CollectionsSectionSet.filesAndAudio:
            return fileAndAudioMessages
        case CollectionsSectionSet.videos:
            return videoMessages
        case CollectionsSectionSet.links:
            return linkMessages
        default: fatal("Unknown section")
        }
    }

    fileprivate func numberOfElements(for section: CollectionsSectionSet) -> Int {
        switch section {
        case CollectionsSectionSet.images:
            let max = inOverviewMode ? maxOverviewElementsInGrid(in: section) : Int.max
            return min(imageMessages.count, max)

        case CollectionsSectionSet.filesAndAudio:
            let max = inOverviewMode ? maxOverviewElementsInTable : Int.max
            return min(fileAndAudioMessages.count, max)

        case CollectionsSectionSet.videos:
            let max = inOverviewMode ? maxOverviewElementsInGrid(in: section) : Int.max
            return min(videoMessages.count, max)

        case CollectionsSectionSet.links:
            let max = inOverviewMode ? maxOverviewElementsInTable : Int.max
            return min(linkMessages.count, max)

        case CollectionsSectionSet.loading:
            return 1

        default: fatal("Unknown section")
        }
    }

    fileprivate func totalNumberOfElements() -> Int {
        // Empty collection contains one element (loading cell)
        return CollectionsSectionSet.visible.map { numberOfElements(for: $0) }.reduce(0, +) - 1
    }

    fileprivate func moreElementsToSee(in section: CollectionsSectionSet) -> Bool {
        return elements(for: section).count > numberOfElements(for: section)
    }

    fileprivate func message(for indexPath: IndexPath) -> ZMConversationMessage {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }

        return elements(for: section)[indexPath.row]
    }

    fileprivate func gridElementSize(in section: CollectionsSectionSet) -> CGSize {
        let sectionHorizontalInset = horizontalInset(in: section)

        let size = (contentView.collectionView.bounds.size.width - sectionHorizontalInset) / CGFloat(elementsPerLine(in: section))

        return CGSize(width: size - 1, height: size - 1)
    }

    fileprivate func elementsPerLine(in section: CollectionsSectionSet) -> Int {
        var count: Int = 1
        let sectionHorizontalInset = horizontalInset(in: section)

        repeat {
            count += 1
        } while ((contentView.collectionView.bounds.size.width - sectionHorizontalInset) / CGFloat(count) > CollectionImageCell.maxCellSize)

        return count
    }

    fileprivate func maxOverviewElementsInGrid(in section: CollectionsSectionSet) -> Int {
        return elementsPerLine(in: section) * 2 // 2 lines of elements
    }

    fileprivate var maxOverviewElementsInTable: Int {
        return 3
    }

    fileprivate func sizeForCell(at indexPath: IndexPath) -> (CGFloat?, CGFloat?) {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }

        let gridElementSize = self.gridElementSize(in: section)

        var desiredWidth: CGFloat?
        var desiredHeight: CGFloat?

        switch section {
        case CollectionsSectionSet.images, CollectionsSectionSet.videos:
            desiredWidth = gridElementSize.width
            desiredHeight = gridElementSize.height

        case CollectionsSectionSet.filesAndAudio:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = 96
            }

        case CollectionsSectionSet.links:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = 98
            }

        case CollectionsSectionSet.loading:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = fetchingDone ? 24 : 88
            }

        default: fatal("Unknown section")
        }

        return (desiredWidth, desiredHeight)
    }

    fileprivate func horizontalInset(in section: CollectionsSectionSet) -> CGFloat {
        let insets = sectionInsets(in: section)
        return insets.left + insets.right
    }

    fileprivate func sectionInsets(in section: CollectionsSectionSet) -> UIEdgeInsets {
        if section == CollectionsSectionSet.loading {
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }

        return elements(for: section).isEmpty ? .zero: UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }

    // MARK: - Data Source

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return CollectionsSectionSet.visible.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }

        return numberOfElements(for: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let (width, height) = sizeForCell(at: indexPath)
        return CGSize(width: width ?? 0, height: height ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }

        let resultCell: CollectionCell

        switch section {
        case CollectionsSectionSet.images:
            resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionImageCell.reuseIdentifier, for: indexPath) as! CollectionImageCell

        case CollectionsSectionSet.filesAndAudio:
            if message(for: indexPath).fileMessageData?.isAudio == true {
                resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionAudioCell.reuseIdentifier, for: indexPath) as! CollectionAudioCell
            } else {
                resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionFileCell.reuseIdentifier, for: indexPath) as! CollectionFileCell
            }

        case CollectionsSectionSet.videos:
            resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionVideoCell.reuseIdentifier, for: indexPath) as! CollectionVideoCell

        case CollectionsSectionSet.links:
            resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionLinkCell.reuseIdentifier, for: indexPath) as! CollectionLinkCell

        case CollectionsSectionSet.loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionLoadingCell.reuseIdentifier, for: indexPath) as! CollectionLoadingCell
            cell.collapsed = fetchingDone
            cell.containerWidth = collectionView.bounds.size.width - horizontalInset(in: section)
            return cell

        default: fatal("Unknown section")
        }

        let message = self.message(for: indexPath)
        resultCell.message = message
        resultCell.delegate = self
        resultCell.messageChangeDelegate = self

        if CollectionsView.useAutolayout {
            let (width, height) = sizeForCell(at: indexPath)

            resultCell.desiredWidth = width
            resultCell.desiredHeight = height
        }

        return resultCell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section")
        }

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionHeaderView.reuseIdentifier, for: indexPath) as! CollectionHeaderView
            header.section = section
            header.totalItemsCount = UInt(moreElementsToSee(in: section) ? elements(for: section).count : 0)
            header.selectionAction = { [weak self] section in
                guard let `self` = self else {
                    return
                }
                let collectionController = CollectionsViewController(collection: self.collection, sections: section, messages: self.elements(for: section), fetchingDone: self.fetchingDone)
                collectionController.onDismiss = self.onDismiss
                collectionController.delegate = self.delegate
                self.navigationController?.pushViewController(collectionController, animated: true)
            }
            let size = self.collectionView(collectionView, layout: self.contentView.collectionView.collectionViewLayout, referenceSizeForHeaderInSection: indexPath.section)
            header.desiredWidth = size.width
            header.desiredHeight = size.height
            return header
        default:
            fatal("No supplementary view for \(kind)")
        }
    }

    // MARK: - Layout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }

        if section == CollectionsSectionSet.loading {
            return .zero
        }
        return elements(for: section).isEmpty ? .zero : CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = CollectionsSectionSet(index: UInt(section)) else {
            fatal("Unknown section")
        }
        return sectionInsets(in: section)
    }

    // MARK: - Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
            fatal("Unknown section for indexPath = \(indexPath)")
        }

        if section == .loading {
            return
        }

        let message = self.message(for: indexPath)

        perform(.present, for: message, source: nil)
    }

}

extension CollectionsViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let section = CollectionsSectionSet(index: UInt(indexPath.section)) else {
                fatal("Unknown section")
            }

            guard section != .loading else {
                continue
            }
        }
    }
}

// MARK: - Message Change

extension CollectionsViewController: CollectionCellMessageChangeDelegate {
    func messageDidChange(_ cell: CollectionCell, changeInfo: MessageChangeInfo) {

        // Open the file when it is downloaded
        guard let message = selectedMessage,
              changeInfo.message == message,
              let fileMessageData = message.fileMessageData,
              fileMessageData.downloadState == .downloaded,
              messagePresenter.waitingForFileDownload,
              message.isFile || message.isVideo || message.isAudio else {
            return
        }

        messagePresenter.openFileMessage(message, targetView: cell)
    }
}

// MARK: - Gestures

extension CollectionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if navigationController?.interactivePopGestureRecognizer == gestureRecognizer {
            return navigationController?.viewControllers.count > 1
        } else {
            return true
        }
    }
}

// MARK: - Actions
extension CollectionsViewController: MessageActionResponder {
    func perform(action: MessageAction, for message: ZMConversationMessage!, view: UIView) {
        perform(action, for: message, source: view as? CollectionCell)
    }
}

extension CollectionsViewController: CollectionCellDelegate {

    func collectionCell(_ cell: CollectionCell, performAction action: MessageAction) {
        guard let message = cell.message else {
            fatal("Cell does not have a message: \(cell)")
        }

        perform(action, for: message, source: cell)
    }

    func perform(_ action: MessageAction, for message: ZMConversationMessage, source: CollectionCell?) {
        switch action {
        case .copy:
            if let cell = source {
                cell.copyDisplayedContent(in: .general)
            } else {
                message.copy(in: .general)
            }

        case .delete:
            deletionDialogPresenter?.presentDeletionAlertController(forMessage: message, source: source) { [weak self] deleted in
                guard deleted else { return }
                _ = self?.navigationController?.popViewController(animated: true)
                self?.refetchCollection()
            }

        case .present:
            selectedMessage = message

            if message.isImage, !message.isRestricted {
                let imagesController = ConversationImagesViewController(collection: collection, initialMessage: message)

                let backButton = CollectionsView.backButton()
                backButton.addTarget(self, action: #selector(CollectionsViewController.backButtonPressed(_:)), for: .touchUpInside)

                let closeButton = CollectionsView.closeButton()
                closeButton.addTarget(self, action: #selector(CollectionsViewController.closeButtonPressed(_:)), for: .touchUpInside)

                imagesController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
                imagesController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
                imagesController.swipeToDismiss = false
                imagesController.messageActionDelegate = self
                navigationController?.pushViewController(imagesController, animated: true)
            } else {
                messagePresenter.open(message, targetView: view, actionResponder: self)
            }

        case .save:
            if message.isImage {
                guard let imageMessageData = message.imageMessageData, let imageData = imageMessageData.imageData else { return }

                let saveableImage = SavableImage(data: imageData, isGIF: imageMessageData.isAnimatedGIF)
                saveableImage.saveToLibrary()

            } else {
                guard let saveController = UIActivityViewController(message: message, from: view) else { return }
                present(saveController, animated: true, completion: nil)
            }

        case .download:
            ZMUserSession.shared()?.enqueue {
                message.fileMessageData?.requestFileDownload()
            }

        case .cancel:
            ZMUserSession.shared()?.enqueue {
                message.fileMessageData?.cancelTransfer()
            }

        case .like:
            ZMUserSession.shared()?.enqueue {
                Message.setLikedMessage(message, liked: !message.liked)
            }

        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            present(detailsViewController, animated: true)

        default:
            delegate?.collectionsViewController(self, performAction: action, onMessage: message)
        }
    }

}
