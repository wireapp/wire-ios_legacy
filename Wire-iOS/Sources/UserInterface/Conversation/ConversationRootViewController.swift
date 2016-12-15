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

@objc open class ConversationRootViewController: UIViewController, UINavigationBarDelegate {
    
    fileprivate var navigationSeparator = UIView()
    fileprivate var customNavBar = UINavigationBar()
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
        self.customNavBar.delegate = self
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
            customNavBar.height == CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? 44 : 64)
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

public extension ConversationViewController {
    
    func barButtonItem(withType type: ZetaIconType, target: AnyObject?, action: Selector, accessibilityIdentifier: String?) -> UIBarButtonItem {
        let button = IconButton.iconButtonDefault()
        button.setIcon(type, with: .tiny, for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -16)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier
        return UIBarButtonItem(customView: button)
    }
    
    var audioCallBarButtonItem: UIBarButtonItem {
        return barButtonItem(withType: .callAudio, target: self, action:  #selector(ConversationViewController.voiceCallItemTapped(_:)), accessibilityIdentifier: "audioCallBarButton")
    }
    
    var videoCallBarButtonItem: UIBarButtonItem {
        return barButtonItem(withType: .callVideo, target: self, action: #selector(ConversationViewController.videoCallItemTapped(_:)), accessibilityIdentifier: "videoCallBarButton")
    }
    
    public func navigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly else { return [] }
        if conversation.conversationType == .oneOnOne {
            return [audioCallBarButtonItem, videoCallBarButtonItem]
        }

        return [audioCallBarButtonItem]
    }
    
    private func confirmCallInGroup(completion: @escaping (_ accepted: Bool) -> ()) {
        let participantsCount = self.conversation.activeParticipants.count - 1
        let message = "conversation.call.many_participants_confirmation.message".localized(args: participantsCount)
        
        let confirmation = UIAlertController(title: "conversation.call.many_participants_confirmation.title".localized,
                                             message: message,
                                             preferredStyle: .alert)
        
        let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel) { _ in
            completion(false)
        }
        confirmation.addAction(actionCancel)
        
        let actionSend = UIAlertAction(title: "conversation.call.many_participants_confirmation.call".localized, style: .default) { _ in
            completion(true)
        }
        confirmation.addAction(actionSend)
        
        self.present(confirmation, animated: true, completion: .none)
    }
    
    func voiceCallItemTapped(_ sender: UIBarButtonItem) {
        let startCall = {
            ConversationInputBarViewController.endEditingMessage()
            self.conversation.startAudioCall(completionHandler: nil)
            Analytics.shared()?.tagMediaAction(.audioCall, inConversation: self.conversation)
        }
        
        if self.conversation.activeParticipants.count <= 4 {
            startCall()
        }
        else {
            self.confirmCallInGroup { accepted in
                if accepted {
                    startCall()
                }
            }
        }
    }
    
    func videoCallItemTapped(_ sender: UIBarButtonItem) {
        ConversationInputBarViewController.endEditingMessage()
        conversation.startVideoCall(completionHandler: nil)
        Analytics.shared()?.tagMediaAction(.videoCall, inConversation: conversation)
    }
}
