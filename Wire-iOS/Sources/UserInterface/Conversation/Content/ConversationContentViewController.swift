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
}
