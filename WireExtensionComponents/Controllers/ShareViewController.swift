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

public protocol ShareDestination: Hashable {
    var displayName: String { get }
    var securityLevel: ZMConversationSecurityLevel { get }
    func avatarView() -> UIView?
}

public protocol Shareable {
    associatedtype I: ShareDestination
    func share<I>(to: [I])
    func previewView() -> UIView?
}

final public class ShareViewController<D: ShareDestination, S: Shareable>: UIViewController, UITableViewDelegate, UITableViewDataSource, TokenFieldDelegate, UIViewControllerTransitioningDelegate {
    public let destinations: [D]
    public let shareable: S
    private(set) var selectedDestinations: Set<D> = Set() {
        didSet {
            sendButton.isEnabled = self.selectedDestinations.count > 0
        }
    }
    
    public let showPreview: Bool
    public var onDismiss: ((ShareViewController, Bool)->())?
    
    public init(shareable: S, destinations: [D], showPreview: Bool = true) {
        self.destinations = destinations
        self.filteredDestinations = destinations
        self.shareable = shareable
        self.showPreview = showPreview
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let containerView  = UIView()
    var shareablePreviewView: UIView?
    var shareablePreviewWrapper: UIView?
    let searchIcon = UIImageView()
    let topSeparatorView = OverflowSeparatorView()
    let destinationsTableView = UITableView()
    let closeButton = IconButton.iconButtonDefaultLight()
    let sendButton = IconButton.iconButtonDefaultDark()
    let tokenField = TokenField()
    let bottomSeparatorLine = UIView()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.createViews()
        self.createConstraints()
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Search
    
    private var filteredDestinations: [D] = []
    
    private var filterString: String? = .none {
        didSet {
            if let filterString = filterString, !filterString.isEmpty {
                self.filteredDestinations = self.destinations.filter {
                    let name = $0.displayName
                    return name.range(of: filterString, options: .caseInsensitive) != nil
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
        self.onDismiss?(self, false)
    }
    
    public func onSendButtonPressed(sender: AnyObject?) {
        if self.selectedDestinations.count > 0 {
            self.shareable.share(to: Array(self.selectedDestinations))
            self.onDismiss?(self, true)
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
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BlurEffectTransition(visualEffectView: blurView, crossfadingViews: [containerView], reverse: false)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BlurEffectTransition(visualEffectView: blurView, crossfadingViews: [containerView], reverse: true)
    }
    
}
