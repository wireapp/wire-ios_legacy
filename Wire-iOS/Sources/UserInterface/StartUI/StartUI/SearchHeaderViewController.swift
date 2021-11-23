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
import Cartography
import UIKit
import WireDataModel

protocol SearchHeaderViewControllerDelegate: AnyObject {
    func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String)
    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController)
}

class SearchHeaderViewController: UIViewController {

    let tokenFieldContainer = UIView()
    let tokenField = TokenField()
    let searchIcon = UIImageView()
    let clearButton: IconButton
    let userSelection: UserSelection
    let colorSchemeVariant: ColorSchemeVariant
    var allowsMultipleSelection: Bool = true

    weak var delegate: SearchHeaderViewControllerDelegate?

    var query: String {
        return tokenField.filterText
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(userSelection: UserSelection, variant: ColorSchemeVariant) {
        self.userSelection = userSelection
        self.colorSchemeVariant = variant
        self.clearButton = IconButton(style: .default, variant: variant)

        super.init(nibName: nil, bundle: nil)

        userSelection.add(observer: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)

        searchIcon.setIcon(.search, size: .tiny, color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))

        clearButton.accessibilityLabel = "clear"
        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.alpha = 0.4
        clearButton.isHidden = true

        tokenField.layer.cornerRadius = 4
        tokenField.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        tokenField.tokenTitleColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        tokenField.tokenSelectedTitleColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        tokenField.clipsToBounds = true
        tokenField.textView.placeholderTextColor = UIColor.from(scheme: .tokenFieldTextPlaceHolder, variant: colorSchemeVariant)
        tokenField.textView.backgroundColor = UIColor.from(scheme: .tokenFieldBackground, variant: colorSchemeVariant)
        tokenField.textView.accessibilityIdentifier = "textViewSearch"
        tokenField.textView.placeholder = "peoplepicker.search_placeholder".localized(uppercased: true)
        tokenField.textView.keyboardAppearance = ColorScheme.keyboardAppearance(for: colorSchemeVariant)
        tokenField.textView.returnKeyType = .done
        tokenField.textView.autocorrectionType = .no
        tokenField.textView.textContainerInset = UIEdgeInsets(top: 9, left: 40, bottom: 11, right: 32)
        tokenField.delegate = self

        [tokenField, searchIcon, clearButton].forEach(tokenFieldContainer.addSubview)
        [tokenFieldContainer].forEach(view.addSubview)

        createConstraints()
    }

    private func createConstraints() {
        constrain(tokenFieldContainer, tokenField, searchIcon, clearButton) { container, tokenField, searchIcon, clearButton in
            searchIcon.centerY == tokenField.centerY
            searchIcon.leading == tokenField.leading + 8

            clearButton.width == 32
            clearButton.height == clearButton.width
            clearButton.centerY == tokenField.centerY
            clearButton.trailing == tokenField.trailing

            tokenField.height >= 40
            tokenField.top >= container.top + 8
            tokenField.bottom <= container.bottom - 8
            tokenField.leading == container.leading + 8
            tokenField.trailing == container.trailing - 8
            tokenField.centerY == container.centerY
        }

        // pin to the bottom of the navigation bar

        tokenFieldContainer.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true

        constrain(view, tokenFieldContainer) { view, tokenFieldContainer in
            tokenFieldContainer.bottom == view.bottom
            tokenFieldContainer.leading == view.leading
            tokenFieldContainer.trailing == view.trailing
            tokenFieldContainer.height == 56
        }
    }

    @objc private dynamic func onClearButtonPressed() {
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
