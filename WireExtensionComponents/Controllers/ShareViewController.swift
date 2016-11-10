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

public protocol ShareDestination: Hashable {
    var displayName: String { get }
}

public protocol Shareable {
    associatedtype I: ShareDestination
    func share<I>(to: [I])
    func previewView() -> UIView
}

final public class ShareViewController<D: ShareDestination, S: Shareable>: UIViewController, UITableViewDelegate, UITableViewDataSource, TokenFieldDelegate {
    public let destinations: [D]
    public let shareable: S
    private(set) var selectedDestinations: Set<D> = Set() {
        didSet {
            sendButton.isEnabled = self.selectedDestinations.count > 0
        }
    }
    
    public var onDismiss: ((ShareViewController)->())?
    
    public init(shareable: S, destinations: [D]) {
        self.destinations = destinations
        self.shareable = shareable
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var blurView: UIVisualEffectView!
    private var shareablePreviewView: UIView!
    private var destinationsTableView: UITableView!
    private var closeButton: IconButton!
    private var sendButton: IconButton!
    private var tokenField: TokenField!
    private var bottomSeparatorLine: UIView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        self.blurView = UIVisualEffectView(effect: effect)
        
        self.shareablePreviewView = self.shareable.previewView()
        self.shareablePreviewView.isUserInteractionEnabled = false
        
        self.tokenField = TokenField()
        self.tokenField.delegate = self
        
        self.destinationsTableView = UITableView()
        self.destinationsTableView.backgroundColor = .clear
        
        self.destinationsTableView.register(ShareDestinationCell<D>.self, forCellReuseIdentifier: ShareDestinationCell<D>.reuseIdentifier)
        
        self.destinationsTableView.separatorStyle = .none
        self.destinationsTableView.allowsMultipleSelection = true
        self.destinationsTableView.delegate = self
        self.destinationsTableView.dataSource = self
        
        self.closeButton = IconButton()
        self.closeButton.cas_styleClass = "default-dark"
        self.closeButton.setIcon(.X, with: .tiny, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)
        
        self.sendButton = IconButton()
        self.sendButton.cas_styleClass = "default-dark"
        self.sendButton.isEnabled = false
        self.sendButton.setIcon(.send, with: .large, for: .normal)
        self.sendButton.addTarget(self, action: #selector(ShareViewController.onSendButtonPressed(sender:)), for: .touchUpInside)
        
        self.bottomSeparatorLine = UIView()
        self.bottomSeparatorLine.cas_styleClass = "separator"
        
        [self.blurView, self.shareablePreviewView, self.tokenField, self.destinationsTableView, self.closeButton, self.sendButton, self.bottomSeparatorLine].forEach(self.view.addSubview)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self.view, self.blurView) { view, blurView in
            blurView.edges == view.edges
        }
        
        constrain(self.view, self.destinationsTableView, self.shareablePreviewView, self.tokenField, self.bottomSeparatorLine) { view, tableView, shareablePreviewView, tokenField, bottomSeparatorLine in
            
            shareablePreviewView.top == view.top + 28
            shareablePreviewView.left == view.left
            shareablePreviewView.right == view.right
            shareablePreviewView.height <= 200
            
            tokenField.top == shareablePreviewView.bottom + 16
            tokenField.left == view.left
            tokenField.right == view.right
            
            tableView.left == view.left
            tableView.right == view.right
            tableView.top == tokenField.bottom
            tableView.bottom == bottomSeparatorLine.top
            
            bottomSeparatorLine.left == view.left
            bottomSeparatorLine.right == view.right
            bottomSeparatorLine.height == 0.5
        }
        
        constrain(self.view, self.closeButton, self.sendButton, self.bottomSeparatorLine) { view, closeButton, sendButton, bottomSeparatorLine in
            
            closeButton.left == view.left + 16
            closeButton.centerY == sendButton.centerY
            closeButton.width == 44
            closeButton.height == closeButton.width
            
            sendButton.top == bottomSeparatorLine.bottom
            sendButton.height == 56
            sendButton.width == sendButton.height
            sendButton.centerX == view.centerX
            sendButton.bottom == view.bottom
        }
    }
    
    
    // MARK: - Actions
    
    public func onCloseButtonPressed(sender: AnyObject?) {
        self.onDismiss?(self)
    }
    
    public func onSendButtonPressed(sender: AnyObject?) {
        if self.selectedDestinations.count > 0 {
            self.shareable.share(to: Array(self.selectedDestinations))
            self.onDismiss?(self)
        }
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.destinations.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShareDestinationCell<D>.reuseIdentifier) as! ShareDestinationCell<D>
        
        let destination = self.destinations[indexPath.row]
        cell.destination = destination
        cell.isSelected = self.selectedDestinations.contains(destination)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    // MARK: - TokenFieldDelegate

//    private func tokenField(_ tokenField: TokenField!, changedTokensTo tokens: [AnyObject]!) {
//        self.selectedConversations = tokens.map { (($0 as! Token).representedObject as! ShareDestination) }
//    }
//    
//    func tokenField(_ tokenField: TokenField!, changedFilterTextTo text: String!) {
//        self.conversationListController.searchTerm = text
//    }
//    
//    func tokenFieldString(forCollapsedState tokenField: TokenField!) -> String! {
//        if (self.recipientList.count > 1) {
//            return NSString.localizedStringWithFormat(NSLocalizedString("sharing-ext.recipients-field.collapsed", comment: "Name of first user + number of others more") as NSString,
//                self.recipientList[0].displayName, self.recipientList.count-1) as String
//        } else if (self.recipientList.count > 0) {
//            return self.recipientList[0].displayName
//        } else {
//            return ""
//        }
//    }

}
