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

class CustomTokenField {
    private var isEditing: Bool = false {
        didSet {
            tokenField.layer.borderColor = isEditing
            ? style.activeBorderColor.cgColor
            : style.borderColor.cgColor
        }
    }
    private var style: SearchBarStyle
    lazy var tokenField: TokenField = {
        let view = TokenField()
        view.applyStyle(self.style)
        view.customTokenFieldDelegate = self
        return view
    }()
    init(style searchBarStyle: SearchBarStyle) {
        self.style = searchBarStyle
    }
    func setIsEditing() {
        self.isEditing = true
    }
    func resetIsEditing() {
        self.isEditing = false
    }
}

final class SearchHeaderViewController: UIViewController {

    let tokenFieldContainer = UIView()
    let customTokenField = CustomTokenField(style: .tokenFieldSearchBar)
    let searchIcon = UIImageView()
    let clearButton: IconButton
    let userSelection: UserSelection
    let colorSchemeVariant: ColorSchemeVariant
    var allowsMultipleSelection: Bool = true

    weak var delegate: SearchHeaderViewControllerDelegate?

    var query: String {
        return customTokenField.tokenField.filterText
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(userSelection: UserSelection, variant: ColorSchemeVariant) {
        self.userSelection = userSelection
        colorSchemeVariant = variant
        clearButton = IconButton(style: .default, variant: variant)

        super.init(nibName: nil, bundle: nil)

        userSelection.add(observer: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)

        searchIcon.setIcon(
            .search,
            size: .tiny,
            color: SemanticColors.Icon.magnifyingGlassButton)

        clearButton.accessibilityLabel = "clear"
        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.isHidden = true

        clearButton.setIconColor(
            SemanticColors.Icon.clearButton,
            for: .normal)
        customTokenField.tokenField.clipsToBounds = true
        customTokenField.tokenField.textView.accessibilityIdentifier = "textViewSearch"
        customTokenField.tokenField.textView.placeholder = "peoplepicker.search_placeholder".localized(uppercased: true)
        customTokenField.tokenField.textView.keyboardAppearance = ColorScheme.keyboardAppearance(for: colorSchemeVariant)
        customTokenField.tokenField.textView.returnKeyType = .done
        customTokenField.tokenField.textView.autocorrectionType = .no
        customTokenField.tokenField.textView.textContainerInset = UIEdgeInsets(top: 9, left: 40, bottom: 11, right: 32)
        customTokenField.tokenField.delegate = self

        [customTokenField.tokenField, searchIcon, clearButton].forEach(tokenFieldContainer.addSubview)
        [tokenFieldContainer].forEach(view.addSubview)

        createConstraints()
    }

    private func createConstraints() {
        [tokenFieldContainer, customTokenField.tokenField, searchIcon, clearButton, tokenFieldContainer].prepareForLayout()
        NSLayoutConstraint.activate([
          searchIcon.centerYAnchor.constraint(equalTo: customTokenField.tokenField.centerYAnchor),
          searchIcon.leadingAnchor.constraint(equalTo: customTokenField.tokenField.leadingAnchor, constant: 16),

          clearButton.widthAnchor.constraint(equalToConstant: 16),
          clearButton.heightAnchor.constraint(equalTo: clearButton.widthAnchor),
          clearButton.centerYAnchor.constraint(equalTo: customTokenField.tokenField.centerYAnchor),
          clearButton.trailingAnchor.constraint(equalTo: customTokenField.tokenField.trailingAnchor, constant: -16),

          customTokenField.tokenField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
          customTokenField.tokenField.topAnchor.constraint(greaterThanOrEqualTo: tokenFieldContainer.topAnchor, constant: 8),
          customTokenField.tokenField.bottomAnchor.constraint(lessThanOrEqualTo: tokenFieldContainer.bottomAnchor, constant: -8),
          customTokenField.tokenField.leadingAnchor.constraint(equalTo: tokenFieldContainer.leadingAnchor, constant: 8),
          customTokenField.tokenField.trailingAnchor.constraint(equalTo: tokenFieldContainer.trailingAnchor, constant: -8),
          customTokenField.tokenField.centerYAnchor.constraint(equalTo: tokenFieldContainer.centerYAnchor),

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
        customTokenField.tokenField.clearFilterText()
        customTokenField.tokenField.removeAllTokens()
        resetQuery()
        updateClearIndicator(for: customTokenField.tokenField)
    }

    func clearInput() {
        customTokenField.tokenField.removeAllTokens()
        customTokenField.tokenField.clearFilterText()
        userSelection.replace([])
    }

    func resetQuery() {
        customTokenField.tokenField.filterUnwantedAttachments()
        delegate?.searchHeaderViewController(self, updatedSearchQuery: customTokenField.tokenField.filterText)
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
        customTokenField.tokenField.addToken(forTitle: user.name ?? "", representedObject: user)
    }

    func userSelection(_ userSelection: UserSelection, didRemoveUser user: UserType) {
        guard let token = customTokenField.tokenField.token(forRepresentedObject: user) else { return }
        customTokenField.tokenField.removeToken(token)
        updateClearIndicator(for: customTokenField.tokenField)
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
