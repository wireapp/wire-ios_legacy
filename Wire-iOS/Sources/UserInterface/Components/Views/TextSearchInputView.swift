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

protocol TextSearchInputViewDelegate: AnyObject {
    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo: String)
    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool
}

final class TextSearchInputView: UIView {
    let iconView = UIImageView()
    let searchInput = UITextView()
    let placeholderLabel = UILabel()
    let cancelButton = IconButton(style: .default)

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

        backgroundColor = UIColor.from(scheme: .barBackground)

        iconView.setIcon(.search, size: .tiny, color: UIColor.from(scheme: .textForeground))
        iconView.contentMode = .center

        searchInput.delegate = self
        searchInput.autocorrectionType = .no
        searchInput.accessibilityLabel = "Search"
        searchInput.accessibilityIdentifier = "search input"
        searchInput.keyboardAppearance = ColorScheme.default.keyboardAppearance
        searchInput.layer.cornerRadius = 4
        searchInput.backgroundColor = UIColor.from(scheme: .tokenFieldBackground)
        searchInput.textContainerInset = UIEdgeInsets(top: 10, left: 40, bottom: 10, right: 8)
        searchInput.font = .normalFont
        searchInput.textColor = .from(scheme: .textForeground)

        placeholderLabel.textAlignment = .natural
        placeholderLabel.isAccessibilityElement = false
        placeholderLabel.font = .smallRegularFont
        placeholderLabel.textColor = .from(scheme: .textDimmed)

        cancelButton.setIcon(.clearInput, size: .tiny, for: .normal)
        cancelButton.addTarget(self, action: #selector(TextSearchInputView.onCancelButtonTouchUpInside(_:)), for: .touchUpInside)
        cancelButton.isHidden = true
        cancelButton.accessibilityIdentifier = "cancel search"

        spinner.color = UIColor.from(scheme: .textDimmed, variant: .light)
        spinner.iconSize = StyleKitIcon.Size.tiny.rawValue
        [iconView, searchInput, cancelButton, placeholderLabel, spinner].forEach(addSubview)

        createConstraints()
    }

    private func createConstraints() {
        [self, iconView, searchInput, placeholderLabel, cancelButton, self, searchInput, cancelButton, spinner].prepareForLayout()

        NSLayoutConstraint.activate(
            searchInput.fitInConstraints(view: self, inset: 8) + [
            iconView.leadingAnchor.constraint(equalTo: searchInput.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: searchInput.centerYAnchor),

            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor),

            heightAnchor.constraint(lessThanOrEqualToConstant: 100),

            placeholderLabel.leadingAnchor.constraint(equalTo: searchInput.leadingAnchor, constant: 48),
            placeholderLabel.topAnchor.constraint(equalTo: searchInput.topAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: searchInput.bottomAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor),

            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: searchInput.trailingAnchor, constant: -8),
            cancelButton.widthAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),
            cancelButton.heightAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),

            spinner.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -6),
            spinner.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
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
        self.searchInput.text = ""
        self.searchInput.resignFirstResponder()
    }

    fileprivate func updatePlaceholderLabel() {
        self.placeholderLabel.isHidden = !self.query.isEmpty
    }

    fileprivate func updateForSearchQuery() {
        self.updatePlaceholderLabel()
        cancelButton.isHidden = self.query.isEmpty
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
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.updatePlaceholderLabel()
    }

}
