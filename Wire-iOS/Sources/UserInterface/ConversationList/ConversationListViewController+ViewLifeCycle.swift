
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

extension ConversationListViewController {

    override open func loadView() {
        view = PassthroughTouchesView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ZMUserSession.shared()?.enqueueChanges({
            self.selectedConversation?.savePendingLastRead()
        })

        requestSuggestedHandlesIfNeeded()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isIPadRegular() {
            Settings.shared().lastViewedScreen = SettingsLastScreen.list
        }
        
        setStateValue(.conversationList)
        
        updateBottomBarSeparatorVisibility(with: listContentController)
        closePushPermissionDialogIfNotNeeded()
        
        shouldAnimateNetworkStatusView = true
        
        if !viewDidAppearCalled {
            viewDidAppearCalled = true
            ZClientViewController.shared()?.showDataUsagePermissionDialogIfNeeded()
            ZClientViewController.shared()?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        if let presentedViewController = presentedViewController,
            presentedViewController is UIAlertController {
            return presentedViewController.preferredStatusBarStyle
        }

        return .lightContent
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        }) { context in
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    override open var shouldAutorotate: Bool {
        return true
    }

    override open var definesPresentationContext: Bool {
        get {
            return true
        }

        set {
            super.definesPresentationContext = newValue
        }
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}
