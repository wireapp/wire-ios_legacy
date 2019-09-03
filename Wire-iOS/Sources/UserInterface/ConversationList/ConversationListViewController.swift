
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

enum ConversationListState {
    case conversationList
    case peoplePicker
    case archived
}

final class ConversationListViewController: UIViewController {
    private(set) var selectedConversation: ZMConversation?
    var usernameTakeoverViewController: UserNameTakeOverViewController?
    var isComingFromSetUsername = false
    var startCallToken: Any?
    var account: Account?
    private(set) var state: ConversationListState?

    var noConversationLabel: UILabel!
    var pushPermissionDeniedViewController: PermissionDeniedViewController?
    var actionsController: ConversationActionController?
    var viewDidAppearCalled = false
    //@property (readwrite, nonatomic, nonnull) UIView *contentContainer; ///TODO: private set

    /// oberser Tokens which are assigned when viewDidLoad
    var userObserverToken: Any?
    var allConversationsObserverToken: Any?
    var connectionRequestsObserverToken: Any?
    var initialSyncObserverToken: Any?
    var userProfileObserverToken: NSObject?

    weak var userProfile: UserProfile?

    ///TODO: non-optional
    var contentContainer: UIView!
    var listContentController: ConversationListContentController!
    var bottomBarController: ConversationListBottomBarController!
    private(set) var topBarViewController: ConversationListTopBarViewController!
    var networkStatusViewController: NetworkStatusViewController!

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false
    var conversationListContainer: UIView?
    var bottomBarBottomOffset: NSLayoutConstraint?
    var bottomBarToolTipConstraint: NSLayoutConstraint?
    var contentControllerBottomInset: CGFloat = 0.0

    var onboardingHint: ConversationListOnboardingHint?

    func setSelectedConversation(_ conversation: ZMConversation) {
    }

    func setStateValue(_ newState: ConversationListState) {
    }

    deinit {
        removeUserProfileObserver()
    }
}
