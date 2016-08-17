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
import zmessaging
import Cartography

@objc public class ConversationRootViewController: UIViewController, UINavigationBarDelegate {
    
    private var navigationSeparator = UIView()
    private var customNavBar = UINavigationBar()
    private var contentView = UIView()
    
    public private(set) weak var conversationViewController: ConversationViewController?
    
    public init(conversation: ZMConversation, clientViewController: ZClientViewController) {
        let conversationController = ConversationViewController()
        conversationController.conversation = conversation
        conversationController.zClientViewController = clientViewController
        
        super.init(nibName: .None, bundle: .None)
        
        self.addChildViewController(conversationController)
        self.contentView.addSubview(conversationController.view)
        conversationController.didMoveToParentViewController(self)
        
        conversationViewController = conversationController
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure() {
        guard let conversationViewController = self.conversationViewController else {
            return
        }
        
        self.navigationSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        self.customNavBar.translucent = false
        self.customNavBar.opaque = true
        self.customNavBar.delegate = self
        self.customNavBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        self.customNavBar.shadowImage = UIImage()
        self.customNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.customNavBar)
        self.navigationSeparator.cas_styleClass = "separator"
        self.view.addSubview(navigationSeparator)
        self.view.addSubview(self.contentView)
        
        constrain(self.customNavBar, self.navigationSeparator, self.view, self.contentView, conversationViewController.view) { customNavBar, navigationSeparator, view, contentView, conversationViewControllerView in
            navigationSeparator.height == 0.5
            navigationSeparator.left == customNavBar.left
            navigationSeparator.top == customNavBar.bottom - 1
            navigationSeparator.right == customNavBar.right
            
            customNavBar.top == view.top
            customNavBar.height == CGFloat(UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 44 : 64)
            customNavBar.left == view.left
            customNavBar.right == view.right
            
            contentView.left == view.left
            contentView.right == view.right
            contentView.bottom == view.bottom
            contentView.top == navigationSeparator.bottom
            
            conversationViewControllerView.edges == contentView.edges
        }
        
        self.customNavBar.pushNavigationItem(conversationViewController.navigationItem, animated: false)
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        delay(0.4) {
            UIApplication.sharedApplication().wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    public override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        switch ColorScheme.defaultColorScheme().variant {
        case .Light:
            return .Default
        case .Dark:
            return .LightContent
        }
    }
}

public extension ConversationViewController {
    
    func barButtonItem(withType type: ZetaIconType, target: AnyObject?, action: Selector, accessibilityIdentifier: String?) -> UIBarButtonItem {
        let button = IconButton.iconButtonDefault()
        button.setIcon(type, withSize: .Tiny, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -16)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        button.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier
        return UIBarButtonItem(customView: button)
    }
    
    var audioCallBarButtonItem: UIBarButtonItem {
        return barButtonItem(withType: .CallAudio, target: self, action:  #selector(ConversationViewController.voiceCallItemTapped(_:)), accessibilityIdentifier: "audioCallBarButton")
    }
    
    var videoCallBarButtonItem: UIBarButtonItem {
        return barButtonItem(withType: .CallVideo, target: self, action: #selector(ConversationViewController.videoCallItemTapped(_:)), accessibilityIdentifier: "videoCallBarButton")
    }
    
    public func navigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly else { return [] }
        if conversation.conversationType == .OneOnOne {
            return [audioCallBarButtonItem, videoCallBarButtonItem]
        }

        return [audioCallBarButtonItem]
    }
    
    func voiceCallItemTapped(sender: UIBarButtonItem) {
        ConversationInputBarViewController.endEditingMessage()
        conversation.startAudioCallWithCompletionHandler(nil)
        Analytics.shared()?.tagMediaAction(.AudioCall, inConversation: conversation)
    }
    
    func videoCallItemTapped(sender: UIBarButtonItem) {
        ConversationInputBarViewController.endEditingMessage()
        conversation.startVideoCallWithCompletionHandler(nil)
        Analytics.shared()?.tagMediaAction(.VideoCall, inConversation: conversation)
    }
}
