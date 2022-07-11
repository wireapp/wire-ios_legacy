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
import WireCommonComponents
import WireSystem

class CustomSearchBar {
    private var isEditing: Bool = false {
        didSet {
            searchBar.layer.borderColor = isEditing
            ? style.activeBorderColor.cgColor
            : style.borderColor.cgColor
        }
    }
    private var style: SearchBarStyle
    lazy var searchBar: UITextView = {
        let textView = UITextView()
        textView.applyStyle(self.style)
        return textView
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

protocol TextSearchInputViewDelegate: AnyObject {
    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo: String)
    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool
}

final class TextSearchInputView: UIView {
    let iconView = UIImageView()
    let customSearchBar = CustomSearchBar(style: .textViewSearchBar)
    let placeholderLabel = UILabel()
    let clearButton = IconButton(style: .default)

    private let spinner = ProgressSpinner()

    weak var delegate: TextSearchInputViewDelegate?
    var query: String = "" {
        didSet {
            self.updateForSearchQuery()
            self.delegate?.searchView(self, didChangeQueryTo: self.query)
        }
    }

    var placeholderString: String = "" {
        didSet {
            self.placeholderLabel.text = placeholderString
        }
    }

    var isLoading: Bool = false {
        didSet {
            spinner.isAnimating = isLoading
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = SemanticColors.SearchBarColor.backgroundSearchBar
        iconView.setIcon(
            .search,
            size: .tiny,
            color: SemanticColors.Icon.magnifyingGlassButton)
        iconView.contentMode = .center
        customSearchBar.searchBar.delegate = self
        customSearchBar.searchBar.autocorrectionType = .no
        customSearchBar.searchBar.accessibilityLabel = "Search"
        customSearchBar.searchBar.accessibilityIdentifier = "search input"
        customSearchBar.searchBar.keyboardAppearance = ColorScheme.default.keyboardAppearance
        customSearchBar.searchBar.textContainerInset = UIEdgeInsets(top: 10, left: 40, bottom: 10, right: 8)
        customSearchBar.searchBar.font = .normalFont
        placeholderLabel.textAlignment = .natural
        placeholderLabel.isAccessibilityElement = false
        placeholderLabel.font = .smallRegularFont
        placeholderLabel.applyStyle(.searchBarPlaceholder)

        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(TextSearchInputView.onCancelButtonTouchUpInside(_:)), for: .touchUpInside)
        clearButton.isHidden = true
        clearButton.accessibilityIdentifier = "cancel search"

        spinner.color = UIColor.from(scheme: .textDimmed, variant: .light)
        spinner.iconSize = StyleKitIcon.Size.tiny.rawValue
        [iconView, customSearchBar.searchBar, clearButton, placeholderLabel, spinner].forEach(addSubview)

        createConstraints()
    }

    private func createConstraints() {
        [self, iconView, customSearchBar.searchBar, placeholderLabel, clearButton, self, customSearchBar.searchBar, clearButton, spinner].prepareForLayout()

        NSLayoutConstraint.activate(
            customSearchBar.searchBar.fitInConstraints(view: self, inset: 8) + [
            iconView.leadingAnchor.constraint(equalTo: customSearchBar.searchBar.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: customSearchBar.searchBar.centerYAnchor),

            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor),

            heightAnchor.constraint(lessThanOrEqualToConstant: 100),

            placeholderLabel.leadingAnchor.constraint(equalTo: customSearchBar.searchBar.leadingAnchor, constant: 48),
            placeholderLabel.topAnchor.constraint(equalTo: customSearchBar.searchBar.topAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: customSearchBar.searchBar.bottomAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor),

            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: customSearchBar.searchBar.trailingAnchor, constant: -16),
            clearButton.widthAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),
            clearButton.heightAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),

            spinner.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -6),
            spinner.centerYAnchor.constraint(equalTo: clearButton.centerYAnchor),
            spinner.widthAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    @objc
    func onCancelButtonTouchUpInside(_ sender: AnyObject!) {
        self.query = ""
        self.customSearchBar.searchBar.text = ""
        self.customSearchBar.searchBar.resignFirstResponder()
    }

    fileprivate func updatePlaceholderLabel() {
        self.placeholderLabel.isHidden = !self.query.isEmpty
    }

    fileprivate func updateForSearchQuery() {
        self.updatePlaceholderLabel()
        clearButton.isHidden = self.query.isEmpty
    }
}

extension TextSearchInputView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let currentText = textView.text else {
            return true
        }
        let containsReturn = text.rangeOfCharacter(from: .newlines, options: [], range: .none) != .none

        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)
        self.query = containsReturn ? currentText : newText

        if containsReturn {
            let shouldReturn = delegate?.searchViewShouldReturn(self) ?? true
            if shouldReturn {
                textView.resignFirstResponder()
            }
        }

        return !containsReturn
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.updatePlaceholderLabel()
        customSearchBar.setIsEditing()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        self.updatePlaceholderLabel()
        customSearchBar.resetIsEditing()
    }

}
