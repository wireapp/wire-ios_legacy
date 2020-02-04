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

/// The main conversation view controller

final class ConversationContentViewController: UIViewController {
    weak var delegate: ConversationContentViewControllerDelegate?
    private(set) var conversation: ZMConversation?
    var bottomMargin: CGFloat = 0.0
    private(set) var isScrolledToBottom = false
    weak var mediaController: ConversationMediaController?
    var tableView: UpsideDownTableView!
    var bottomContainer: UIView?
    var searchQueries: [String]?
    var mentionsSearchResultsViewController: UserSearchResultsViewController?
    var dataSource: ConversationTableViewDataSource?
    
    /// The cell whose tools are expanded in the UI. Setting this automatically triggers the expanding in the UI.
    private var messageWithExpandedTools: ZMConversationMessage?
    private var messagePresenter: MessagePresenter?
    private weak var expectedMessageToShow: ZMConversationMessage?
    private var onMessageShown: ((UIView?) -> Void)?
    private weak var pinchImageCell: (UITableViewCell & SelectableView)?
    private var pinchImageView: FLAnimatedImageView?
    private var dimView: UIView?
    private var initialPinchLocation = CGPoint.zero
    private var deletionDialogPresenter: DeletionDialogPresenter?
    private weak var session: ZMUserSessionInterface?
    private var connectionViewController: UserConnectionViewController?
    private var wasScrolledToBottomAtStartOfUpdate = false
    private var activeMediaPlayerObserver: NSObject?
    private var mediaPlaybackManager: MediaPlaybackManager?
    private var cachedRowHeights: [AnyHashable : Any]?
    private var hasDoneInitialLayout = false
    private var onScreen = false
    private weak var messageVisibleOnLoad: ZMConversationMessage?
    
    private func removeHighlightsAndMenu() {
    }
    
    private func setConversationHeaderView(_ headerView: UIView?) {
    }
    
    private func updateVisibleMessagesWindow() {
    }
    
    required init?(coder aDecoder: NSCoder) {
    }
    
    func highlight(_ message: ZMConversationMessage?) {
    }

    deinit {
        // Observer must be deallocated before `mediaPlaybackManager`
        activeMediaPlayerObserver = nil
        mediaPlaybackManager = nil
        
        if nil != tableView {
            tableView.delegate = nil
            tableView.dataSource = nil
        }
        
        pinchImageView.removeFromSuperview()
        dimView.removeFromSuperview()
    }
    
    override func loadView() {
        super.loadView()
        
        tableView = UpsideDownTableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        
        bottomContainer = UIView(frame: CGRect.zero)
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraintEqual(to: view.topAnchor),
            tableView.leadingAnchor.constraintEqual(to: view.leadingAnchor),
            tableView.trailingAnchor.constraintEqual(to: view.trailingAnchor),
            bottomContainer.topAnchor.constraintEqual(to: tableView.bottomAnchor),
            bottomContainer.leadingAnchor.constraintEqual(to: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraintEqual(to: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraintEqual(to: view.bottomAnchor)
            ])
        let heightCollapsingConstraint = bottomContainer.heightAnchor.constraint(equalToConstant: 0)
        heightCollapsingConstraint.priority = .defaultHigh
        heightCollapsingConstraint.isActive = true
    }
    


    convenience init(conversation: ZMConversation,
                     message: ZMConversationMessage? = nil,
                     mediaPlaybackManager: MediaPlaybackManager?,
                     session: ZMUserSessionInterface) {

        self.init(nibName: nil, bundle: nil)

        messageVisibleOnLoad = message ?? conversation.firstUnreadMessage
        cachedRowHeights = NSMutableDictionary()
        messagePresenter = MessagePresenter(mediaPlaybackManager: mediaPlaybackManager)

        self.mediaPlaybackManager = mediaPlaybackManager
        self.conversation = conversation

        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = parent
        self.session = session
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDataSource()
        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.keyboardDismissMode = AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal ? .none : .interactive
        
        UIView.performWithoutAnimation({
            self.tableView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground)
            self.view.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground)
        })
        
        let pinchImageGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(onPinchZoom(_:)))
        pinchImageGestureRecognizer.delegate = self
        view.addGestureRecognizer(pinchImageGestureRecognizer)
        
        createMentionsResultsView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        dataSource?.resetSectionControllers()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateVisibleMessagesWindow()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    override open func viewWillAppear(_ animated: Bool) {
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

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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
            scroll(toMessage: messageVisibleOnLoad, completion: nil)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        ZMLogWarn("Received system memory warning.")
        super.didReceiveMemoryWarning()
    }
    
    func setConversationHeaderView(_ headerView: UIView?) {
        headerView?.frame = headerViewFrame(with: headerView)
        tableView.tableHeaderView = headerView
    }
    
    func setSearchQueries(_ searchQueries: [String]?) {
        if self.searchQueries.count == 0 && searchQueries?.count == 0 {
            return
        }
        
        self.searchQueries = searchQueries
        
        dataSource?.searchQueries = self.searchQueries
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    func willSelectRow(at indexPath: IndexPath, tableView: UITableView) -> IndexPath? {
        guard dataSource?.messages.indices.contains(indexPath.section) == true else { return nil }

        // If the menu is visible, hide it and do nothing
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.setMenuVisible(false, animated: true)
            return nil
        }

        let message = dataSource?.messages[indexPath.section] as? ZMMessage

        if message == dataSource?.selectedMessage {

            // If this cell is already selected, deselect it.
            dataSource?.selectedMessage = nil
            dataSource?.deselect(indexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)

            return nil
        } else {
            if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
                dataSource?.deselect(indexPath: indexPathForSelectedRow)
            }
            dataSource?.selectedMessage = message
            dataSource?.select(indexPath: indexPath)

            return indexPath
        }
    }
    
    // MARK: - Get/set
    var bottomMargin: CGFloat {
        get {
            return super.bottomMargin
        }
        set(bottomMargin) {
            self.bottomMargin = bottomMargin
            setTableViewBottomMargin(bottomMargin)
        }
    }
    
    func setTableViewBottomMargin(_ bottomMargin: CGFloat) {
        let insets = tableView.correctedContentInset
        insets.bottom = bottomMargin
        tableView.setCorrectedContentInset(insets)
        tableView.contentOffset = CGPoint(x: tableView.contentOffset.x, y: -bottomMargin)
    }
    
    func isScrolledToBottom() -> Bool {
        return dataSource?.hasNewerMessagesToLoad == nil && tableView.contentOffset.y + tableView.correctedContentInset.bottom <= 0
    }
    
    // MARK: - Actions
    func highlight(_ message: ZMConversationMessage?) {
        dataSource?.highlight(message)
    }
    
    func updateVisibleMessagesWindow() {
        if UIApplication.shared.applicationState != .active {
            return // We only update the last read if the app is active
        }
        
        var isViewVisible = true
        if view.window == nil {
            isViewVisible = false
        } else if view.hidden {
            isViewVisible = false
        } else if view.alpha == 0 {
            isViewVisible = false
        } else {
            let viewFrameInWindow = view.window.convert(view.bounds, from: view)
            if !viewFrameInWindow.intersects(view.window.bounds) {
                isViewVisible = false
            }
        }
        
        // We should not update last read if the view is not visible to the user
        if !isViewVisible {
            return
        }
        
        //  Workaround to fix incorrect first/last cells in conversation
        //  As described in http://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
        tableView.visibleCells
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows
        let firstIndexPath = indexPathsForVisibleRows?.first
        
        if firstIndexPath != nil {
            weak var lastVisibleMessage = dataSource?.messages[firstIndexPath?.section ?? 0] as? ZMConversationMessage
            
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
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.didEndDisplayingCell()

        cachedRowHeights[indexPath] = NSNumber(value: Float(cell.frame.size.height))
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cachedRowHeights[indexPath] as? CGFloat ?? UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return willSelectRow(at: indexPath, tableView: tableView)
    }
}

extension ConversationContentViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        //no-op
    }
}
