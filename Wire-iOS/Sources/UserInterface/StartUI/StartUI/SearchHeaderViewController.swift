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


@objc
public protocol SearchHeaderViewControllerDelegate : class {
    
    func searchHeaderViewController(_ searchHeaderViewController : SearchHeaderViewController, updatedSearchQuery query: String)
    func searchHeaderViewControllerDidCancelAction(_ searchHeaderViewController : SearchHeaderViewController)
    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController : SearchHeaderViewController)
    
    
}

public class SearchHeaderViewController : UIViewController {
    
    let searchIcon = UIImageView()
    let clearButton: IconButton
    let titleLabel : UILabel = UILabel()
    let tokenField : TokenField = TokenField()
    let closeButton : IconButton
    let userSelection : UserSelection
    let colorSchemeVariant : ColorSchemeVariant
    let separatorView = OverflowSeparatorView()
    
    @objc
    public weak var delegate : SearchHeaderViewControllerDelegate? = nil
    
    public var query : String {
        return tokenField.filterText
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(userSelection: UserSelection, variant: ColorSchemeVariant) {
        self.userSelection = userSelection
        self.colorSchemeVariant = variant
        self.closeButton = variant == .dark ? IconButton.iconButtonDefaultLight() : IconButton.iconButtonDefaultDark()
        self.clearButton = variant == .dark ? IconButton.iconButtonDefaultLight() : IconButton.iconButtonDefaultDark()
        
        super.init(nibName: nil, bundle: nil)
        
        userSelection.add(observer: self)
    }
    
    public override func viewDidLoad() {
        searchIcon.image = UIImage(for: .search, iconSize: .tiny, color: UIColor.wr_color(fromColorScheme: ColorSchemeColorTokenFieldTextPlaceHolder, variant: colorSchemeVariant))
        
        clearButton.accessibilityLabel = "clear"
        clearButton.setIcon(.clearInput, with: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.alpha = 0.4
        clearButton.isHidden = true
        
        titleLabel.text = title?.uppercased()
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant)
        
        tokenField.cas_styleClass = "search"
        tokenField.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant)
        tokenField.layer.cornerRadius = 4
        tokenField.clipsToBounds = true
        tokenField.textView.placeholderTextColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTokenFieldTextPlaceHolder, variant: colorSchemeVariant)
        tokenField.textView.placeholderTextAlignment = .center
        tokenField.textView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTokenFieldBackground, variant: colorSchemeVariant)
        tokenField.textView.accessibilityLabel = "textViewSearch"
        tokenField.textView.placeholder = "peoplepicker.search_placeholder".localized.uppercased()
        tokenField.textView.keyboardAppearance = ColorScheme.keyboardAppearance(for: colorSchemeVariant)
        tokenField.textView.returnKeyType = .done
        tokenField.textView.autocorrectionType = .no
        tokenField.textView.textContainerInset = UIEdgeInsets(top: 6, left: 32, bottom: 6, right: 32)
        tokenField.delegate = self
        
        closeButton.accessibilityLabel = "close"
        closeButton.setIcon(.X, with: .tiny, for: .normal)
        closeButton.addTarget(self, action: #selector(onCloseButtonPressed), for: .touchUpInside)
        
        [titleLabel, tokenField, searchIcon, closeButton, clearButton, separatorView].forEach(view.addSubview)
        
        createConstraints()
    }
    
    fileprivate func createConstraints() {
        constrain(view, tokenField, searchIcon, clearButton) { view, tokenField, searchIcon, clearButton in
            searchIcon.top == tokenField.top + 8
            searchIcon.leading == tokenField.leading + 8
            
            clearButton.height == 32
            clearButton.width == 32
            clearButton.top == tokenField.top
            clearButton.trailing == tokenField.trailing
        }
        
        constrain(view, titleLabel, closeButton, tokenField) { view, titleLabel, closeButton, tokenField in
            titleLabel.top == view.top + 34
            titleLabel.leading == tokenField.leading
            titleLabel.trailing == tokenField.trailing
            
            tokenField.top == view.top + 56
            tokenField.leading == view.leading + 8
            tokenField.trailing == view.trailing - 8
            tokenField.height >= 32
            tokenField.bottom == view.bottom - 8
            
            closeButton.trailing == view.trailing
            closeButton.centerY == titleLabel.centerY
            closeButton.width == 44
            closeButton.height == closeButton.width
        }
        
        constrain(view, separatorView) { view, separatorView in
            separatorView.leading == view.leading
            separatorView.trailing == view.trailing
            separatorView.bottom == view.bottom
        }
    }
    
    fileprivate dynamic func onCloseButtonPressed() {
        delegate?.searchHeaderViewControllerDidCancelAction(self)
    }
    
    fileprivate dynamic func onClearButtonPressed() {
        tokenField.clearFilterText()
        tokenField.removeAllTokens()
        resetQuery()
    }
    
    public func resetQuery() {
        tokenField.filterUnwantedAttachments()
        delegate?.searchHeaderViewController(self, updatedSearchQuery: tokenField.filterText)
    }
    
}

extension SearchHeaderViewController : UserSelectionObserver {
    
    public func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [ZMUser]) {
        // this is triggered by the TokenField itself so we should ignore it here
    }
    
    public func userSelection(_ userSelection: UserSelection, didAddUser user: ZMUser) {
        tokenField.addToken(forTitle: user.displayName, representedObject: user)
    }
    
    public func userSelection(_ userSelection: UserSelection, didRemoveUser user: ZMUser) {
        guard let token = tokenField.token(forRepresentedObject: user) else { return }
        tokenField.removeToken(token)
    }
    
}

extension SearchHeaderViewController : TokenFieldDelegate {
    
    func updateClearIndicator(for tokenField: TokenField) {
        clearButton.isHidden = tokenField.filterText.isEmpty && tokenField.tokens.isEmpty
    }

    public func tokenField(_ tokenField: TokenField, changedTokensTo tokens: [Token]) {
        userSelection.replace(tokens.map { $0.representedObject as! ZMUser })
        updateClearIndicator(for: tokenField)
    }
    
    public func tokenField(_ tokenField: TokenField, changedFilterTextTo text: String) {
        delegate?.searchHeaderViewController(self, updatedSearchQuery: text)
        updateClearIndicator(for: tokenField)
    }
    
    public func tokenFieldDidBeginEditing(_ tokenField: TokenField) {
        
    }
    
    public func tokenFieldWillScroll(_ tokenField: TokenField) {
        
    }
    
    public func tokenFieldDidConfirmSelection(_ controller: TokenField) {
        delegate?.searchHeaderViewControllerDidConfirmAction(self)
    }
}
