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

private let zmLog = ZMSLog(tag: "ConversationContentViewController")

/// The main conversation view controller
final class ConversationContentViewController: UIViewController {
    weak var delegate: ConversationContentViewControllerDelegate?
    let conversation: ZMConversation
    var bottomMargin: CGFloat = 0 {
        didSet {
            setTableViewBottomMargin(bottomMargin)
        }
    }

    let tableView: UpsideDownTableView = UpsideDownTableView(frame: .zero, style: .plain)
    var bottomContainer: UIView = UIView(frame: .zero)
    var searchQueries: [String]? {
        didSet {
            guard let searchQueries = searchQueries,
                !searchQueries.isEmpty else { return }

            dataSource.searchQueries = searchQueries
        }
    }

    let mentionsSearchResultsViewController: UserSearchResultsViewController = UserSearchResultsViewController()
    let dataSource: ConversationTableViewDataSource

    /// The cell whose tools are expanded in the UI. Setting this automatically triggers the expanding in the UI.
    private var messageWithExpandedTools: ZMConversationMessage?
    let messagePresenter: MessagePresenter
    private weak var expectedMessageToShow: ZMConversationMessage?
    private var onMessageShown: ((UIView?) -> Void)?
    private weak var pinchImageCell: (UITableViewCell & SelectableView)?
    private var initialPinchLocation = CGPoint.zero
    var deletionDialogPresenter: DeletionDialogPresenter?
    let session: ZMUserSessionInterface
    var connectionViewController: UserConnectionViewController?
    private var wasScrolledToBottomAtStartOfUpdate = false
    private var activeMediaPlayerObserver: NSObject?
    private var mediaPlaybackManager: MediaPlaybackManager?
    private var cachedRowHeights: [AnyHashable: Any] = [:]
    private var hasDoneInitialLayout = false
    private var onScreen = false
    private weak var messageVisibleOnLoad: ZMConversationMessage?

    init(conversation: ZMConversation,
         message: ZMConversationMessage? = nil,
         mediaPlaybackManager: MediaPlaybackManager?,
         session: ZMUserSessionInterface) {
        messagePresenter = MessagePresenter(mediaPlaybackManager: mediaPlaybackManager)
        self.session = session
        self.conversation = conversation
        messageVisibleOnLoad = message ?? conversation.firstUnreadMessage
                
        dataSource = ConversationTableViewDataSource(conversation: conversation, tableView: tableView, actionResponder: self, cellDelegate: self)

        super.init(nibName: nil, bundle: nil)

        self.mediaPlaybackManager = mediaPlaybackManager
        
        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = parent
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Observer must be deallocated before `mediaPlaybackManager`
        activeMediaPlayerObserver = nil
        mediaPlaybackManager = nil

            tableView.delegate = nil
            tableView.dataSource = nil
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

        createMentionsResultsView()

        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        dataSource.resetSectionControllers()
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateVisibleMessagesWindow()

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }

        UIAccessibility.post(notification: .screenChanged, argument: nil)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onScreen = true
        activeMediaPlayerObserver = mediaPlaybackManager?.observe(\.activeMediaPlayer, options: [.initial, .new]) { [weak self] _, _ in
            self?.updateMediaBar()
        }

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
        return dataSource.hasNewerMessagesToLoad == nil && tableView.contentOffset.y + tableView.correctedContentInset.bottom <= 0
    }

    // MARK: - Actions
    func highlight(_ message: ZMConversationMessage) {
        dataSource.highlight(message: message)
    }

    private func updateVisibleMessagesWindow() {
        if UIApplication.shared.applicationState != .active {
            return // We only update the last read if the app is active
        }

        var isViewVisible = true
        if view.window == nil {
            isViewVisible = false
        } else if view.isHidden {
            isViewVisible = false
        } else if view.alpha == 0 {
            isViewVisible = false
        } else if let window = view.window {
            let viewFrameInWindow = window.convert(view.bounds, from: view)
            if !viewFrameInWindow.intersects(window.bounds) {
                isViewVisible = false
            }
        }

        // We should not update last read if the view is not visible to the user
        if !isViewVisible {
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

        cachedRowHeights[indexPath] = NSNumber(value: Float(cell.frame.size.height))
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.didEndDisplayingCell()

        cachedRowHeights[indexPath] = NSNumber(value: Float(cell.frame.size.height))
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cachedRowHeights[indexPath] as? CGFloat ?? UITableView.automaticDimension
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
