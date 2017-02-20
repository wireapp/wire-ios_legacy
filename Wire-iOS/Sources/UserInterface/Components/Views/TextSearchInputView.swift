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

public final class TextSearchInputView: UIView {
    public let iconView = UIImageView()
    public let searchInput = UITextField()
    public let placeholderLabel = UILabel()
    public let cancelButton = IconButton.iconButtonDefault()

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
        
        let colorScheme = ColorScheme.default()
        iconView.image = UIImage(for: .search, iconSize: .tiny, color: colorScheme.color(withName: ColorSchemeColorTextForeground))
        iconView.contentMode = .center
        
        searchInput.borderStyle = .none
        searchInput.delegate = self
        searchInput.autocorrectionType = .no
        searchInput.accessibilityLabel = "Search"
        searchInput.accessibilityIdentifier = "search input"
        searchInput.keyboardAppearance = ColorScheme.default().keyboardAppearance
        
        placeholderLabel.textAlignment = .center
        placeholderLabel.isAccessibilityElement = false
        
        cancelButton.setIcon(.clearInput, with: .tiny, for: .normal)
        cancelButton.addTarget(self, action: #selector(TextSearchInputView.onCancelButtonTouchUpInside(_:)), for: .touchUpInside)
        cancelButton.isHidden = true
        cancelButton.accessibilityIdentifier = "cancel search"

        spinner.color = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed, variant: .light)
        spinner.iconSize = .tiny
        [iconView, searchInput, cancelButton, placeholderLabel, spinner].forEach(self.addSubview)

        self.createConstraints()
    }
    
    private func createConstraints() {
        constrain(self, iconView, searchInput, placeholderLabel, cancelButton) { selfView, iconView, searchInput, placeholderLabel, cancelButton in
            iconView.leading == selfView.leading
            iconView.width == 48
            iconView.height >= 48
            
            iconView.top == selfView.top
            iconView.bottom == selfView.bottom
            
            selfView.height <= 100
            
            searchInput.leading == iconView.trailing
            searchInput.top == selfView.top
            searchInput.bottom == selfView.bottom

            placeholderLabel.leading == searchInput.leading
            placeholderLabel.top == searchInput.top
            placeholderLabel.bottom == searchInput.bottom
            placeholderLabel.trailing == cancelButton.leading
        }

        constrain(self, searchInput, cancelButton, spinner) { view, searchInput, cancelButton, spinner in
            cancelButton.centerY == view.centerY
            cancelButton.trailing == view.trailing
            cancelButton.width == 48
            cancelButton.height == 48

            spinner.trailing == cancelButton.leading - 6
            spinner.centerY == cancelButton.centerY
            spinner.width == CGFloat(ZetaIconSize.tiny.rawValue)

            searchInput.trailing == spinner.leading - 6
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
        self.placeholderLabel.isHidden = !self.query.isEmpty || self.searchInput.isEditing
    }
    
    fileprivate func updateForSearchQuery() {
        self.updatePlaceholderLabel()
        cancelButton.isHidden = self.query.isEmpty
    }
}

extension TextSearchInputView: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let containsReturn = string.rangeOfCharacter(from: .newlines, options: [], range: .none) != .none
        
        let newText = (text as NSString).replacingCharacters(in: range, with: string)
        self.query = containsReturn ? text : newText
        
        return !containsReturn
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let shouldReturn = delegate?.searchViewShouldReturn(self) ?? true
        if shouldReturn {
            textField.resignFirstResponder()
        }
        return shouldReturn
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.updatePlaceholderLabel()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.updatePlaceholderLabel()
    }
}
