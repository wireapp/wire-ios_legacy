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
        self.filteredDestinations = destinations
        self.shareable = shareable
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var blurView: UIVisualEffectView!
    private var shareablePreviewView: UIView!
    private var shareablePreviewWrapper: UIView!
    private var searchIcon: UIImageView!
    private var topSeparatorView: OverflowSeparatorView!
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
        self.shareablePreviewView.layer.cornerRadius = 4
        self.shareablePreviewView.clipsToBounds = true
        
        self.shareablePreviewWrapper = UIView()
        self.shareablePreviewWrapper.clipsToBounds = false
        self.shareablePreviewWrapper.layer.shadowOpacity = 1
        self.shareablePreviewWrapper.layer.shadowRadius = 8
        self.shareablePreviewWrapper.layer.shadowOffset = CGSize(width: 0, height: 8)
        self.shareablePreviewWrapper.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor
        self.shareablePreviewWrapper.layer.shadowPath = UIBezierPath(rect: self.shareablePreviewView.bounds).cgPath
        
        self.shareablePreviewWrapper.addSubview(self.shareablePreviewView)
        
        self.tokenField = TokenField()
        self.tokenField.textColor = .white
        self.tokenField.layer.cornerRadius = 4
        self.tokenField.clipsToBounds = true
        self.tokenField.textView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.tokenField.textView.accessibilityLabel = "textViewSearch"
        self.tokenField.textView.placeholder = "contacts_ui.search_placeholder"
        self.tokenField.textView.keyboardAppearance = .dark
        self.tokenField.textView.contentInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 12)
        self.tokenField.textView.placeholderTextContainerInset = self.tokenField.textView.contentInset
        self.tokenField.delegate = self
        
        self.searchIcon = UIImageView()
        self.searchIcon.image = UIImage(for: .search, iconSize: .tiny, color: .white)
        
        self.topSeparatorView = OverflowSeparatorView()
        
        self.destinationsTableView = UITableView()
        self.destinationsTableView.backgroundColor = .clear
        self.destinationsTableView.register(ShareDestinationCell<D>.self, forCellReuseIdentifier: ShareDestinationCell<D>.reuseIdentifier)
        self.destinationsTableView.separatorStyle = .none
        self.destinationsTableView.allowsSelection = true
        self.destinationsTableView.allowsMultipleSelection = true
        self.destinationsTableView.delegate = self
        self.destinationsTableView.dataSource = self
        
        self.closeButton = IconButton()
        self.closeButton.accessibilityLabel = "close"
        self.closeButton.cas_styleClass = "default-light"
        self.closeButton.setIcon(.X, with: .tiny, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)
        
        self.sendButton = IconButton()
        self.sendButton.accessibilityLabel = "send"
        self.sendButton.cas_styleClass = "default-dark"
        self.sendButton.isEnabled = false
        self.sendButton.setIcon(.send, with: .tiny, for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor.white, for: .normal)
        self.sendButton.circular = true
        self.sendButton.addTarget(self, action: #selector(ShareViewController.onSendButtonPressed(sender:)), for: .touchUpInside)
        
        self.bottomSeparatorLine = UIView()
        self.bottomSeparatorLine.cas_styleClass = "separator"
        
        [self.blurView, self.shareablePreviewWrapper, self.tokenField, self.destinationsTableView, self.closeButton, self.sendButton, self.bottomSeparatorLine, self.topSeparatorView, self.searchIcon].forEach(self.view.addSubview)
        
        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self.view, self.blurView) { view, blurView in
            blurView.edges == view.edges
        }
        
        constrain(self.shareablePreviewWrapper, self.shareablePreviewView) { shareablePreviewWrapper, shareablePreviewView in
            shareablePreviewView.edges == shareablePreviewWrapper.edges
        }
        
        constrain(self.tokenField, self.searchIcon) { tokenField, searchIcon in
            searchIcon.top == tokenField.top + 12
            searchIcon.left == tokenField.left + 12
        }
        
        constrain(self.view, self.destinationsTableView, self.topSeparatorView) { view, destinationsTableView, topSeparatorView in
            topSeparatorView.left == view.left
            topSeparatorView.right == view.right
            topSeparatorView.top == destinationsTableView.top
            topSeparatorView.height == 0.5
        }
        
        constrain(self.view, self.destinationsTableView, self.shareablePreviewWrapper, self.tokenField, self.bottomSeparatorLine) { view, tableView, shareablePreviewWrapper, tokenField, bottomSeparatorLine in
            
            shareablePreviewWrapper.top == view.top + 28
            shareablePreviewWrapper.left == view.left + 16
            shareablePreviewWrapper.right == -16 + view.right
            shareablePreviewWrapper.height <= 200
            
            tokenField.top == shareablePreviewWrapper.bottom + 16
            tokenField.left == view.left + 8
            tokenField.right == -8 + view.right
            tokenField.height >= 32
            
            tableView.left == view.left
            tableView.right == view.right
            tableView.top == tokenField.bottom + 8
            tableView.bottom == bottomSeparatorLine.top
            
            bottomSeparatorLine.left == view.left
            bottomSeparatorLine.right == view.right
            bottomSeparatorLine.height == 0.5
        }
        
        constrain(self.view, self.closeButton, self.sendButton, self.bottomSeparatorLine) { view, closeButton, sendButton, bottomSeparatorLine in
            
            closeButton.left == view.left + 8
            closeButton.centerY == sendButton.centerY
            closeButton.width == 44
            closeButton.height == closeButton.width
            
            sendButton.top == bottomSeparatorLine.bottom + 12
            sendButton.height == 32
            sendButton.width == sendButton.height
            sendButton.centerX == view.centerX
            sendButton.bottom == -12 + view.bottom
        }
    }
    
    // MARK: - Search
    
    private var filteredDestinations: [D] = []
    
    private var filterString: String? = .none {
        didSet {
            if let filterString = filterString, !filterString.isEmpty {
                self.filteredDestinations = self.destinations.filter {
                    $0.displayName.contains(filterString)
                }
            }
            else {
                self.filteredDestinations = self.destinations
            }
            
            self.destinationsTableView.reloadData()
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
        return self.filteredDestinations.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShareDestinationCell<D>.reuseIdentifier) as! ShareDestinationCell<D>
        
        let destination = self.filteredDestinations[indexPath.row]
        cell.destination = destination
        cell.isSelected = self.selectedDestinations.contains(destination)
        if cell.isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = self.filteredDestinations[indexPath.row]

        self.tokenField.addToken(forTitle: destination.displayName, representedObject: destination)
        
        self.selectedDestinations.insert(destination)
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let destination = self.filteredDestinations[indexPath.row]
        
        guard let token = self.tokenField.token(forRepresentedObject: destination) else {
            return
        }
        self.tokenField.removeToken(token)
        
        self.selectedDestinations.remove(destination)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparatorView.scrollViewDidScroll(scrollView: scrollView)
    }

    // MARK: - TokenFieldDelegate

    public func tokenField(_ tokenField: TokenField, changedTokensTo tokens: [Token]) {
        self.selectedDestinations = Set(tokens.map { $0.representedObject as! D })
        self.destinationsTableView.reloadData()
    }
    
    public func tokenField(_ tokenField: TokenField, changedFilterTextTo text: String) {
        self.filterString = text
    }
    
}
