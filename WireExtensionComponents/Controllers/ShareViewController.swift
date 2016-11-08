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

public protocol ConversationTypeProtocol: Hashable {
    var displayName: String { get }
}

public protocol ShareableMessageType {
    associatedtype I: ConversationTypeProtocol
    func shareTo<I>(conversations: [I])
}

public protocol AccentColorProvider: class {
    var accentColor: UIColor! { get }
}

public protocol ShareViewControllerDelegate: class {
    func shareViewControllerDidShare<I, S>(shareController: ShareViewController<I, S>, conversations:[I])
    func shareViewControllerWantsToBeDismissed<I, S>(shareController: ShareViewController<I, S>)
}

final public class ShareViewController<I: ConversationTypeProtocol, S: ShareableMessageType>: UIViewController, UITableViewDelegate, UITableViewDataSource {
    public let conversations: [I]
    public let shareable: S
    private(set) var selectedConversations: Set<I> = Set() {
        didSet {
            sendButton.isEnabled = self.selectedConversations.count > 0
        }
    }
    
    public override var title: String? {
        didSet {
            guard let titleLabel = self.titleLabel else {
                return
            }

            titleLabel.text = title
        }
    }
    
    public var accentColorProvider: AccentColorProvider?
    public weak var delegate: ShareViewControllerDelegate?
    
    public init(shareable: S, conversations: [I]) {
        self.conversations = conversations
        self.shareable = shareable
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var blurView: UIVisualEffectView!
    private var tableView: UITableView!
    private var closeButton: IconButton!
    private var sendButton: IconButton!
    private var titleLabel: UILabel!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        self.blurView = UIVisualEffectView(effect: effect)
        self.view.addSubview(self.blurView)
        
        self.tableView = UITableView()
        self.tableView.backgroundColor = .clear
        
        self.tableView.register(ShareViewControllerCell<I>.self, forCellReuseIdentifier: ShareViewControllerCell<I>.reuseIdentifier)
        
        self.tableView.separatorStyle = .none
        self.tableView.allowsMultipleSelection = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        
        self.closeButton = IconButton()
        self.closeButton.setIcon(.X, with: .tiny, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.closeButton)
        
        self.sendButton = IconButton()
        self.sendButton.isEnabled = false
        self.sendButton.setIcon(.send, with: .large, for: .normal)
        self.sendButton.addTarget(self, action: #selector(ShareViewController.onSendButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.sendButton)
        
        self.titleLabel = UILabel()
        self.titleLabel.backgroundColor = self.accentColorProvider?.accentColor
        self.view.addSubview(self.titleLabel)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self.view, self.blurView) { view, blurView in
            blurView.edges == view.edges
        }
        
        constrain(self.view, self.tableView, self.closeButton, self.sendButton, self.titleLabel) { view, tableView, closeButton, sendButton, titleLabel in
            
            titleLabel.top == view.top
            titleLabel.left == view.left
            titleLabel.right == view.left
            titleLabel.height == 20
            
            closeButton.centerY == titleLabel.centerY
            closeButton.right == view.right
            closeButton.width == 44
        
            tableView.left == view.left
            tableView.right == view.right
            tableView.top == titleLabel.bottom
            
            sendButton.top == tableView.bottom
            sendButton.height == 44
            sendButton.width == sendButton.height
            sendButton.centerX == view.centerX
            sendButton.bottom == view.bottom
        }
    }
    
    
    // Actions
    
    public func onCloseButtonPressed(sender: AnyObject?) {
        self.delegate?.shareViewControllerWantsToBeDismissed(shareController: self)
    }
    
    public func onSendButtonPressed(sender: AnyObject?) {
        if self.selectedConversations.count > 0 {
            let conversationsToShareTo = Array(self.selectedConversations)
            self.shareable.shareTo(conversations: conversationsToShareTo)
            self.delegate?.shareViewControllerDidShare(shareController: self, conversations: conversationsToShareTo)
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShareViewControllerCell<I>.reuseIdentifier) as! ShareViewControllerCell<I>
        
        let conversation = self.conversations[indexPath.row]
        cell.accentColorProvider = self.accentColorProvider
        cell.conversation = conversation
        cell.isSelected = self.selectedConversations.contains(conversation)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
