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
import Cartography

// This class wraps the conversation content view controller in order to display the navigation bar on the top
final class ConversationRootViewController: UIViewController {

    let navBarContainer: UINavigationBarContainer
    fileprivate var contentView = UIView()
    var navHeight: NSLayoutConstraint?
    var networkStatusBarHeight: NSLayoutConstraint?

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    fileprivate let networkStatusViewController: NetworkStatusViewController = NetworkStatusViewController()

    fileprivate(set) weak var conversationViewController: ConversationViewController?

    init(conversation: ZMConversation,
         message: ZMConversationMessage?,
         clientViewController: ZClientViewController) {
        if let userSession = ZMUserSession.shared() {
        let conversationController = ConversationViewController(session: userSession,
                                                                conversation: conversation,
                                                                visibleMessage: message as? ZMMessage,
                                                                zClientViewController: clientViewController)



        conversationViewController = conversationController
        }
        
        let navbar = UINavigationBar()
        navbar.isTranslucent = false
        navbar.isOpaque = true
        navbar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navbar.shadowImage = UIImage()
        navbar.barTintColor = UIColor.from(scheme: .barBackground)
        navbar.tintColor = UIColor.from(scheme: .textForeground)
        
        navBarContainer = UINavigationBarContainer(navbar)

        super.init(nibName: .none, bundle: .none)

        networkStatusViewController.delegate = self
        
        if let conversationViewController = conversationViewController {
        addChild(conversationViewController)
        contentView.addSubview(conversationViewController.view)
        conversationViewController.didMove(toParent: self)
        }

        conversation.refreshDataIfNeeded()

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        guard let conversationViewController = self.conversationViewController else {
            return
        }

        self.view.backgroundColor = UIColor.from(scheme: .barBackground)

        self.addToSelf(navBarContainer)
        self.view.addSubview(self.contentView)
        self.addToSelf(networkStatusViewController)

        networkStatusViewController.createConstraintsInParentController(bottomView: navBarContainer.view, controller: self)

        constrain(navBarContainer.view, view, contentView, conversationViewController.view) {
            navBarContainer, view, contentView, conversationViewControllerView in

            navBarContainer.left == view.left
            navBarContainer.right == view.right

            contentView.left == view.left
            contentView.right == view.right
            contentView.top == navBarContainer.bottom

            conversationViewControllerView.edges == contentView.edges
        }
        
        contentView.bottomAnchor.constraint(equalTo: self.safeBottomAnchor).isActive = true
        
        navBarContainer.navigationBar.pushItem(conversationViewController.navigationItem, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delay(0.4) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }

        shouldAnimateNetworkStatusView = true
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch ColorScheme.default.variant {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }
    
    @objc (scrollToMessage:)
    func scroll(to message: ZMConversationMessage) {
        conversationViewController?.scroll(to: message)
    }
}


extension ConversationRootViewController: NetworkStatusBarDelegate {
    var bottomMargin: CGFloat {
        return 0
    }

    func showInIPad(networkStatusViewController: NetworkStatusViewController, with orientation: UIInterfaceOrientation) -> Bool {
        // always show on iPad for any orientation in regular mode
        return true
    }
}

extension ZMConversation {
    
    /// Check if the conversation data is out of date, and in case update it.
    /// This in an opportunistic update of the data, with an on-demand strategy.
    /// Whenever the conversation is opened by the user, we check if anything is missing.
    fileprivate func refreshDataIfNeeded() {
        ZMUserSession.shared()?.enqueueChanges {
            self.markToDownloadRolesIfNeeded()
        }
    }
}

