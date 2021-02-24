// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireDataModel
import WireCommonComponents

private let zmLog = ZMSLog(tag: "ConversationContentViewController")

/// The main conversation view controller
final class ConversationContentViewController: UIViewController, PopoverPresenter, SpinnerCapable {
    //MARK: PopoverPresenter
    var presentedPopover: UIPopoverPresentationController?
    var popoverPointToView: UIView?
    var dismissSpinner: SpinnerCompletion?

    weak var delegate: ConversationContentViewControllerDelegate?
    let conversation: ZMConversation
    var bottomMargin: CGFloat = 0 {
        didSet {
            setTableViewBottomMargin(bottomMargin)
        }
    }

    let tableView: UpsideDownTableView = UpsideDownTableView(frame: .zero, style: .plain)
    let bottomContainer: UIView = UIView(frame: .zero)
    var searchQueries: [String]? {
        didSet {
            guard let searchQueries = searchQueries,
                !searchQueries.isEmpty else { return }

            dataSource.searchQueries = searchQueries
        }
    }

    let mentionsSearchResultsViewController: UserSearchResultsViewController = UserSearchResultsViewController()

    lazy var dataSource: ConversationTableViewDataSource = {
        return ConversationTableViewDataSource(conversation: conversation, tableView: tableView, actionResponder: self, cellDelegate: self)
    }()

    let messagePresenter: MessagePresenter
    var deletionDialogPresenter: DeletionDialogPresenter?
    let session: ZMUserSessionInterface
    var connectionViewController: UserConnectionViewController?
    var digitalSignatureToken: Any?
    var userClientToken: Any?
    var isDigitalSignatureVerificationShown: Bool = false

    private var mediaPlaybackManager: MediaPlaybackManager?
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]
    private var hasDoneInitialLayout = false
    private var onScreen = false
    private weak var messageVisibleOnLoad: ZMConversationMessage?
    private var token: NSObjectProtocol?

    init(conversation: ZMConversation,
         message: ZMConversationMessage? = nil,
         mediaPlaybackManager: MediaPlaybackManager?,
         session: ZMUserSessionInterface) {
        messagePresenter = MessagePresenter(mediaPlaybackManager: mediaPlaybackManager)
        self.session = session
        self.conversation = conversation
        messageVisibleOnLoad = message ?? conversation.firstUnreadMessage

        super.init(nibName: nil, bundle: nil)

        self.mediaPlaybackManager = mediaPlaybackManager

        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = parent

        token = NotificationCenter.default.addObserver(forName: .activeMediaPlayerChanged, object: nil, queue: .main) { [weak self] _ in
            self?.updateMediaBar()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        view.addSubview(tableView)

        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        let heightCollapsingConstraint = bottomContainer.heightAnchor.constraint(equalToConstant: 0)
        heightCollapsingConstraint.priority = .defaultHigh
        heightCollapsingConstraint.isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.keyboardDismissMode = AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal ? .none : .interactive

        tableView.backgroundColor = UIColor.from(scheme: .contentBackground)
        view.backgroundColor = UIColor.from(scheme: .contentBackground)

        setupMentionsResultsView()

        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        dataSource.resetSectionControllers()
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateVisibleMessagesWindow()

        if #available(iOS 13, *) {
            // handle Context menu in table view delegate
        } else {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
            }
        }

        UIAccessibility.post(notification: .screenChanged, argument: nil)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onScreen = true

        for cell in tableView.visibleCells {
            cell.willDisplayCell()
        }

        messagePresenter.modalTargetController = parent

        updateHeaderHeight()

        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        onScreen = false
        removeHighlightsAndMenu()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollToFirstUnreadMessageIfNeeded()
        updatePopover()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator?) {

        guard let coordinator = coordinator else { return }

        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.updatePopoverSourceRect()
        }
    }

    func setupMentionsResultsView() {
        mentionsSearchResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(mentionsSearchResultsViewController)
        view.addSubview(mentionsSearchResultsViewController.view)

        mentionsSearchResultsViewController.view.fitInSuperview()
    }

    func scrollToFirstUnreadMessageIfNeeded() {
        if !hasDoneInitialLayout {
            hasDoneInitialLayout = true
            scroll(to: messageVisibleOnLoad)
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        zmLog.warn("Received system memory warning.")
        super.didReceiveMemoryWarning()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    func setConversationHeaderView(_ headerView: UIView) {
        headerView.frame = headerViewFrame(view: headerView)
        tableView.tableHeaderView = headerView
    }

    @discardableResult
    func willSelectRow(at indexPath: IndexPath, tableView: UITableView) -> IndexPath? {
        guard dataSource.messages.indices.contains(indexPath.section) == true else { return nil }

        // If the menu is visible, hide it and do nothing
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.setMenuVisible(false, animated: true)
            return nil
        }

        let message = dataSource.messages[indexPath.section] as? ZMMessage

        if message == dataSource.selectedMessage {

            // If this cell is already selected, deselect it.
            dataSource.selectedMessage = nil
            dataSource.deselect(indexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)

            return nil
        } else {
            if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
                dataSource.deselect(indexPath: indexPathForSelectedRow)
            }
            dataSource.selectedMessage = message
            dataSource.select(indexPath: indexPath)

            return indexPath
        }
    }

    // MARK: - Get/set

    func setTableViewBottomMargin(_ bottomMargin: CGFloat) {
        var insets = tableView.correctedContentInset
        insets.bottom = bottomMargin
        tableView.correctedContentInset = insets
        tableView.contentOffset = CGPoint(x: tableView.contentOffset.x, y: -bottomMargin)
    }

    var isScrolledToBottom: Bool {
        return !dataSource.hasNewerMessagesToLoad &&
               tableView.contentOffset.y + tableView.correctedContentInset.bottom <= 0
    }

    // MARK: - Actions
    func highlight(_ message: ZMConversationMessage) {
        dataSource.highlight(message: message)
    }

    private func updateVisibleMessagesWindow() {
        guard UIApplication.shared.applicationState == .active else {
            return // We only update the last read if the app is active
        }

        // We should not update last read if the view is not visible to the user

        guard let window = view.window,
            window.convert(view.bounds, from: view).intersects(window.bounds) else {
                return
        }

        guard !view.isHidden, view.alpha != 0 else {
            return
        }

        //  Workaround to fix incorrect first/last cells in conversation
        //  As described in http://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
        _ = tableView.visibleCells

        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows

        if let firstIndexPath = indexPathsForVisibleRows?.first {
            let lastVisibleMessage = dataSource.messages[firstIndexPath.section]
            conversation.markMessagesAsRead(until: lastVisibleMessage)
        }

        /// update media bar visiblity
        updateMediaBar()
    }

    // MARK: - Custom UI, utilities

    func removeHighlightsAndMenu() {
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    func didFinishEditing(_ message: ZMConversationMessage?) {
        dataSource.editingMessage = nil
    }

    // MARK: - MediaPlayer

    private func updateMediaBar() {
        let mediaPlayingMessage = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage

        if let mediaPlayingMessage = mediaPlayingMessage,
            mediaPlayingMessage.conversationLike === conversation,
            !displaysMessage(mediaPlayingMessage),
            !mediaPlayingMessage.isVideo {
            DispatchQueue.main.async(execute: {
                self.delegate?.conversationContentViewController(self, didEndDisplayingActiveMediaPlayerFor: mediaPlayingMessage)
            })
        } else {
            DispatchQueue.main.async(execute: {
                self.delegate?.conversationContentViewController(self, willDisplayActiveMediaPlayerFor: mediaPlayingMessage)
            })
        }
    }

    private func displaysMessage(_ message: ZMConversationMessage) -> Bool {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return false }

        let index = dataSource.indexOfMessage(message)

        for indexPath in indexPathsForVisibleRows {
            if indexPath.section == index {
                return true
            }
        }

        return false
    }
}

// MARK: - TableView

extension ConversationContentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if onScreen {
            cell.willDisplayCell()
        }

        // using dispatch_async because when this method gets run, the cell is not yet in visible cells,
        // so the update will fail
        // dispatch_async runs it with next runloop, when the cell has been added to visible cells
        DispatchQueue.main.async(execute: {
            self.updateVisibleMessagesWindow()
        })

        cachedRowHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.didEndDisplayingCell()

        cachedRowHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cachedRowHeights[indexPath] ?? UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return willSelectRow(at: indexPath, tableView: tableView)
    }
}

extension ConversationContentViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        //no-op
    }
}
