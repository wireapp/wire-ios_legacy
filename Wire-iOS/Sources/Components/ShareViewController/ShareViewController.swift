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
import UIKit
import WireDataModel

protocol ShareDestination: Hashable {
    var displayName: String { get }
    var securityLevel: ZMConversationSecurityLevel { get }
    var showsGuestIcon: Bool { get }
    var isUnderLegalHold: Bool { get }
    var avatarView: UIView? { get }
}

protocol Shareable {
    associatedtype I: ShareDestination
    func share<I>(to: [I])
    func previewView() -> UIView?
}

final class ShareViewController<D: ShareDestination & NSObjectProtocol, S: Shareable>: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let destinations: [D]
    let shareable: S
    private(set) var selectedDestinations: Set<D> = Set() {
        didSet {
            sendButton.isEnabled = self.selectedDestinations.count > 0
        }
    }

    var tokenFieldTopConstraint: NSLayoutConstraint?
    var tokenFieldShareablePreviewSpacingConstraint: NSLayoutConstraint?
    var shareablePreviewTopConstraint: NSLayoutConstraint?

    var showPreview: Bool {
        didSet {
            shareablePreviewWrapper?.isHidden = !showPreview

            updateShareablePreviewConstraint()
        }
    }

    func updateShareablePreviewConstraint() {
        if showPreview {
            tokenFieldTopConstraint?.isActive = false
            shareablePreviewTopConstraint?.isActive = true
            tokenFieldShareablePreviewSpacingConstraint?.isActive = true
        } else {
            shareablePreviewTopConstraint?.isActive = false
            tokenFieldShareablePreviewSpacingConstraint?.isActive = false
            tokenFieldTopConstraint?.isActive = true
        }
    }

    let allowsMultipleSelection: Bool
    var onDismiss: ((ShareViewController, Bool) -> Void)?
    var bottomConstraint: NSLayoutConstraint?

    init(shareable: S, destinations: [D], showPreview: Bool = true, allowsMultipleSelection: Bool = true) {
        self.destinations = destinations
        self.filteredDestinations = destinations
        self.shareable = shareable
        self.showPreview = showPreview
        self.allowsMultipleSelection = allowsMultipleSelection
        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameWillChange(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange(notification:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
        createViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let containerView  = UIView()
    var shareablePreviewView: UIView?
    var shareablePreviewWrapper: UIView?
    let searchIcon = UIImageView()
    let topSeparatorView = OverflowSeparatorView()
    let destinationsTableView = UITableView()
    let closeButton = IconButton(style: .default)
    let sendButton = IconButton(style: .default)

    let clearButton = IconButton(style: .default)
    let tokenField = TokenField()
    let bottomSeparatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        return view
    }()

    // MARK: - Search

    private var filteredDestinations: [D] = []

    private var filterString: String? = .none {
        didSet {
            if let filterString = filterString, !filterString.isEmpty {
                self.filteredDestinations = self.destinations.filter {
                    let name = $0.displayName
                    return name.range(of: filterString, options: .caseInsensitive) != nil
                }
            } else {
                self.filteredDestinations = self.destinations
            }

            self.destinationsTableView.reloadData()
        }
    }

    // MARK: - Actions

    @objc
    func onCloseButtonPressed(sender: AnyObject?) {
        onDismiss?(self, false)
    }

    @objc
    func onSendButtonPressed(sender: AnyObject?) {
        if self.selectedDestinations.count > 0 {
            self.shareable.share(to: Array(self.selectedDestinations))
            self.onDismiss?(self, true)
        }
    }

    @objc
    func onClearButtonPressed() {
        tokenField.clearFilterText()
        tokenField.removeAllTokens()
        updateClearIndicator(for: tokenField)
    }

    func resetQuery() {
        tokenField.filterUnwantedAttachments()
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDestinations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShareDestinationCell<D>.reuseIdentifier) as! ShareDestinationCell<D>

        let destination = self.filteredDestinations[indexPath.row]
        cell.destination = destination
        cell.allowsMultipleSelection = self.allowsMultipleSelection
        cell.isSelected = self.selectedDestinations.contains(destination)
        if cell.isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = self.filteredDestinations[indexPath.row]

        tokenField.addToken(forTitle: destination.displayName, representedObject: destination)

        self.selectedDestinations.insert(destination)

        if !self.allowsMultipleSelection {
            self.onSendButtonPressed(sender: nil)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let destination = self.filteredDestinations[indexPath.row]

        guard let token = self.tokenField.token(forRepresentedObject: destination) else {
            return
        }
        self.tokenField.removeToken(token)

        self.selectedDestinations.remove(destination)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparatorView.scrollViewDidScroll(scrollView: scrollView)
    }

    @objc
    private func keyboardFrameWillChange(notification: Notification) {
        let inputAccessoryHeight = UIResponder.currentFirst?.inputAccessoryView?.bounds.size.height ?? 0

        UIView.animate(withKeyboardNotification: notification, in: self.view, animations: {[weak self] (keyboardFrameInView) in
            guard let weakSelf = self else { return }

            let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight
            weakSelf.bottomConstraint?.constant = keyboardHeight == 0 ? -weakSelf.view.safeAreaInsetsOrFallback.bottom : CGFloat(0)
            weakSelf.view.layoutIfNeeded()
        })
    }

    @objc
    private func keyboardFrameDidChange(notification: Notification) {
        updatePopoverFrame()
    }

    private func updateClearIndicator(for tokenField: TokenField) {
        clearButton.isHidden = tokenField.filterText.isEmpty && tokenField.tokens.isEmpty
    }
}

// MARK: - TokenFieldDelegate

extension ShareViewController: TokenFieldDelegate {
    func tokenField(_ tokenField: TokenField, changedTokensTo tokens: [Token<NSObjectProtocol>]) {
        selectedDestinations = Set(tokens.map { $0.representedObject.value as! D })
        destinationsTableView.reloadData()
    }

    func tokenField(_ tokenField: TokenField, changedFilterTextTo text: String) {
        updateClearIndicator(for: tokenField)
        filterString = text
    }

    func tokenFieldDidConfirmSelection(_ controller: TokenField) {
        // no-op
    }

}
