//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

protocol SearchHeaderViewControllerDelegate: AnyObject {
    func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String)
    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController)
}

final class SearchHeaderViewController: UIViewController {

    let tokenFieldContainer = UIView()
    let tokenField = TokenField()
    let searchIcon = UIImageView()
    let clearButton: IconButton
    let userSelection: UserSelection
    var allowsMultipleSelection: Bool = true

    weak var delegate: SearchHeaderViewControllerDelegate?
    var query: String {
        return tokenField.filterText
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(userSelection: UserSelection) {
        self.userSelection = userSelection
        clearButton = IconButton(style: .default)

        super.init(nibName: nil, bundle: nil)

        userSelection.add(observer: self)
        tokenField.tokenTitleColor = SemanticColors.SearchBar.textInputView.resolvedColor(with: traitCollection)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault

        searchIcon.setTemplateIcon(.search, size: .tiny)
        searchIcon.tintColor = SemanticColors.SearchBar.backgroundButton

        clearButton.accessibilityLabel = L10n.Accessibility.SearchView.ClearButton.description
        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.isHidden = true
        clearButton.setIconColor(SemanticColors.SearchBar.backgroundButton, for: .normal)

        tokenField.textView.accessibilityIdentifier = "textViewSearch"
        tokenField.tokenTitleColor = SemanticColors.SearchBar.textInputView.resolvedColor(with: traitCollection)
        tokenField.textView.placeholder = L10n.Localizable.Peoplepicker.searchPlaceholder.capitalized
        tokenField.textView.keyboardAppearance = .default
        tokenField.textView.returnKeyType = .done
        tokenField.textView.autocorrectionType = .no
        tokenField.textView.textContainerInset = UIEdgeInsets(top: 9, left: 40, bottom: 11, right: 32)
        tokenField.delegate = self

        [tokenField, searchIcon, clearButton].forEach(tokenFieldContainer.addSubview)
        [tokenFieldContainer].forEach(view.addSubview)

        createConstraints()
    }

    private func createConstraints() {
        [tokenFieldContainer, tokenField, searchIcon, clearButton, tokenFieldContainer].prepareForLayout()
        NSLayoutConstraint.activate([
          searchIcon.centerYAnchor.constraint(equalTo: tokenField.centerYAnchor),
          searchIcon.leadingAnchor.constraint(equalTo: tokenField.leadingAnchor, constant: 16),

          clearButton.widthAnchor.constraint(equalToConstant: 16),
          clearButton.heightAnchor.constraint(equalTo: clearButton.widthAnchor),
          clearButton.centerYAnchor.constraint(equalTo: tokenField.centerYAnchor),
          clearButton.trailingAnchor.constraint(equalTo: tokenField.trailingAnchor, constant: -16),

          tokenField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
          tokenField.topAnchor.constraint(greaterThanOrEqualTo: tokenFieldContainer.topAnchor, constant: 8),
          tokenField.bottomAnchor.constraint(lessThanOrEqualTo: tokenFieldContainer.bottomAnchor, constant: -8),
          tokenField.leadingAnchor.constraint(equalTo: tokenFieldContainer.leadingAnchor, constant: 8),
          tokenField.trailingAnchor.constraint(equalTo: tokenFieldContainer.trailingAnchor, constant: -8),
          tokenField.centerYAnchor.constraint(equalTo: tokenFieldContainer.centerYAnchor),

        // pin to the bottom of the navigation bar

        tokenFieldContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

          tokenFieldContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          tokenFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          tokenFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
          tokenFieldContainer.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc
    private func onClearButtonPressed() {
        tokenField.clearFilterText()
        tokenField.removeAllTokens()
        resetQuery()
        updateClearIndicator(for: tokenField)
    }

    func clearInput() {
        tokenField.removeAllTokens()
        tokenField.clearFilterText()
        userSelection.replace([])
    }

    func resetQuery() {
        tokenField.filterUnwantedAttachments()
        delegate?.searchHeaderViewController(self, updatedSearchQuery: tokenField.filterText)
    }

    private func updateClearIndicator(for tokenField: TokenField) {
        clearButton.isHidden = tokenField.filterText.isEmpty && tokenField.tokens.isEmpty
    }

}

extension SearchHeaderViewController: UserSelectionObserver {

    func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [UserType]) {
        // this is triggered by the TokenField itself so we should ignore it here
    }

    func userSelection(_ userSelection: UserSelection, didAddUser user: UserType) {
        guard allowsMultipleSelection else { return }
        tokenField.addToken(forTitle: user.name ?? "", representedObject: user)
    }

    func userSelection(_ userSelection: UserSelection, didRemoveUser user: UserType) {
        guard let token = tokenField.token(forRepresentedObject: user) else { return }
        tokenField.removeToken(token)
        updateClearIndicator(for: tokenField)
    }

}

extension SearchHeaderViewController: TokenFieldDelegate {

    func tokenField(_ tokenField: TokenField, changedTokensTo tokens: [Token<NSObjectProtocol>]) {
        userSelection.replace(tokens.compactMap { $0.representedObject.value as? UserType })
        updateClearIndicator(for: tokenField)
    }

    func tokenField(_ tokenField: TokenField, changedFilterTextTo text: String) {
        delegate?.searchHeaderViewController(self, updatedSearchQuery: text)
        updateClearIndicator(for: tokenField)
    }

    func tokenFieldDidConfirmSelection(_ controller: TokenField) {
        delegate?.searchHeaderViewControllerDidConfirmAction(self)
    }
}
