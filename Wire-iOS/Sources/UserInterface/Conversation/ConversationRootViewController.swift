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
@objc open class ConversationRootViewController: UIViewController {
    
    fileprivate var navigationSeparator = UIView()
    fileprivate(set) var customNavBar = UINavigationBar()
    fileprivate var contentView = UIView()
    
    open fileprivate(set) weak var conversationViewController: ConversationViewController?
    
    public init(conversation: ZMConversation, clientViewController: ZClientViewController) {
        let conversationController = ConversationViewController()
        conversationController.conversation = conversation
        conversationController.zClientViewController = clientViewController
        
        super.init(nibName: .none, bundle: .none)
        
        self.addChildViewController(conversationController)
        self.contentView.addSubview(conversationController.view)
        conversationController.didMove(toParentViewController: self)
        
        conversationViewController = conversationController
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func configure() {
        guard let conversationViewController = self.conversationViewController else {
            return
        }
        
        self.navigationSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        self.customNavBar.isTranslucent = false
        self.customNavBar.isOpaque = true
        self.customNavBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        self.customNavBar.shadowImage = UIImage()
        self.customNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.customNavBar)
        self.navigationSeparator.cas_styleClass = "separator"
        self.view.addSubview(navigationSeparator)
        self.view.addSubview(self.contentView)
        
        constrain(self.customNavBar, self.navigationSeparator, self.view, self.contentView, conversationViewController.view) { (customNavBar: LayoutProxy, navigationSeparator: LayoutProxy, view: LayoutProxy, contentView: LayoutProxy, conversationViewControllerView: LayoutProxy) -> () in
            navigationSeparator.height == 0.5
            navigationSeparator.left == customNavBar.left
            navigationSeparator.top == customNavBar.bottom - 1
            navigationSeparator.right == customNavBar.right
            
            customNavBar.top == view.top
            customNavBar.height == 64
            customNavBar.left == view.left
            customNavBar.right == view.right
            
            contentView.left == view.left
            contentView.right == view.right
            contentView.bottom == view.bottom
            contentView.top == navigationSeparator.bottom
            
            conversationViewControllerView.edges == contentView.edges
        }
        
        self.customNavBar.pushItem(conversationViewController.navigationItem, animated: false)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delay(0.4) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    open override var prefersStatusBarHidden : Bool {
        return false
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        switch ColorScheme.default().variant {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }
}
