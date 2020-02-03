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

extension ConversationContentViewController {
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
