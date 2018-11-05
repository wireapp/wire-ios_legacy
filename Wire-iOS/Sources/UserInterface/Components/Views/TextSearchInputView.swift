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

public protocol TextSearchInputViewDelegate: class {
    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo: String)
    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool
}

@objcMembers public final class TextSearchInputView: UIView {
    public let iconView = UIImageView()
    public let searchInput = UITextView()
    public let placeholderLabel = UILabel()
    public let cancelButton = IconButton(style: .default)

    private let spinner = ProgressSpinner()
    
    public weak var delegate: TextSearchInputViewDelegate?
    public var query: String = "" {
        didSet {
            self.updateForSearchQuery()
            self.delegate?.searchView(self, didChangeQueryTo: self.query)
        }
    }
    
    public var placeholderString: String = "" {
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
        
        iconView.image = UIImage(for: .search, iconSize: .tiny, color: UIColor.from(scheme: .textForeground))
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

        cancelButton.setIcon(.clearInput, with: .tiny, for: .normal)
        cancelButton.addTarget(self, action: #selector(TextSearchInputView.onCancelButtonTouchUpInside(_:)), for: .touchUpInside)
        cancelButton.isHidden = true
        cancelButton.accessibilityIdentifier = "cancel search"

        spinner.color = UIColor.from(scheme: .textDimmed, variant: .light)
        spinner.iconSize = .tiny
        [iconView, searchInput, cancelButton, placeholderLabel, spinner].forEach(self.addSubview)

        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self, iconView, searchInput, placeholderLabel, cancelButton) { selfView, iconView, searchInput, placeholderLabel, cancelButton in
            iconView.leading == searchInput.leading + 8
            iconView.centerY == searchInput.centerY
            
            iconView.top == selfView.top
            iconView.bottom == selfView.bottom
            
            selfView.height <= 100
            
            searchInput.edges == inset(selfView.edges, UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

            placeholderLabel.leading == searchInput.leading + 48
            placeholderLabel.top == searchInput.top
            placeholderLabel.bottom == searchInput.bottom
            placeholderLabel.trailing == cancelButton.leading
        }

        constrain(self, searchInput, cancelButton, spinner) { view, searchInput, cancelButton, spinner in
            cancelButton.centerY == view.centerY
            cancelButton.trailing == searchInput.trailing - 8
            cancelButton.width == UIImage.size(for: .tiny)
            cancelButton.height == UIImage.size(for: .tiny)

            spinner.trailing == cancelButton.leading - 6
            spinner.centerY == cancelButton.centerY
            spinner.width == UIImage.size(for: .tiny)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatal("init?(coder aDecoder: NSCoder) is not implemented")
    }
    
    @objc public func onCancelButtonTouchUpInside(_ sender: AnyObject!) {
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
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
        
    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.updatePlaceholderLabel()
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.updatePlaceholderLabel()
    }

}
