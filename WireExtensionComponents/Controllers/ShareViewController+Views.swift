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
import Cartography


extension ShareViewController {
    internal func createViews() {
        let effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        self.blurView = UIVisualEffectView(effect: effect)
        
        if self.showPreview {
            let shareablePreviewView = self.shareable.previewView()
            shareablePreviewView.layer.cornerRadius = 4
            shareablePreviewView.clipsToBounds = true
            self.shareablePreviewView = shareablePreviewView
            
            let shareablePreviewWrapper = UIView()
            shareablePreviewWrapper.clipsToBounds = false
            shareablePreviewWrapper.layer.shadowOpacity = 1
            shareablePreviewWrapper.layer.shadowRadius = 8
            shareablePreviewWrapper.layer.shadowOffset = CGSize(width: 0, height: 8)
            shareablePreviewWrapper.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor
            
            shareablePreviewWrapper.addSubview(shareablePreviewView)
            self.shareablePreviewWrapper = shareablePreviewWrapper
        }
        
        self.tokenField = TokenField()
        self.tokenField.cas_styleClass = "share"
        self.tokenField.textColor = .white
        self.tokenField.layer.cornerRadius = 4
        self.tokenField.clipsToBounds = true
        self.tokenField.textView.placeholderTextAlignment = .center
        self.tokenField.textView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.tokenField.textView.accessibilityLabel = "textViewSearch"
        self.tokenField.textView.placeholder = "content.message.forward.to".localized.uppercased()
        self.tokenField.textView.keyboardAppearance = .dark
        self.tokenField.textView.textContainerInset = UIEdgeInsets(top: 6, left: 48, bottom: 6, right: 12)
        self.tokenField.delegate = self
        
        self.searchIcon = UIImageView()
        self.searchIcon.image = UIImage(for: .search, iconSize: .small, color: .white)
        
        self.topSeparatorView = OverflowSeparatorView()
        
        self.destinationsTableView = UITableView()
        self.destinationsTableView.backgroundColor = .clear
        self.destinationsTableView.register(ShareDestinationCell<D>.self, forCellReuseIdentifier: ShareDestinationCell<D>.reuseIdentifier)
        self.destinationsTableView.separatorStyle = .none
        self.destinationsTableView.allowsSelection = true
        self.destinationsTableView.allowsMultipleSelection = true
        self.destinationsTableView.keyboardDismissMode = .interactive
        self.destinationsTableView.delegate = self
        self.destinationsTableView.dataSource = self
        
        self.closeButton = IconButton.iconButtonDefaultLight()
        self.closeButton.accessibilityLabel = "close"
        self.closeButton.setIcon(.X, with: .tiny, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)
        
        self.sendButton = IconButton.iconButtonDefaultDark()
        self.sendButton.accessibilityLabel = "send"
        self.sendButton.isEnabled = false
        self.sendButton.setIcon(.send, with: .tiny, for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor.white, for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor(white: 0.64, alpha: 1), for: .disabled)
        self.sendButton.setBorderColor(.clear, for: .normal)
        self.sendButton.setBorderColor(.clear, for: .disabled)
        self.sendButton.circular = true
        self.sendButton.addTarget(self, action: #selector(ShareViewController.onSendButtonPressed(sender:)), for: .touchUpInside)
        
        self.bottomSeparatorLine = UIView()
        self.bottomSeparatorLine.cas_styleClass = "separator"
        
        [self.blurView, self.containerView].forEach(self.view.addSubview)
        [self.tokenField, self.destinationsTableView, self.closeButton, self.sendButton, self.bottomSeparatorLine, self.topSeparatorView, self.searchIcon].forEach(self.containerView.addSubview)
        
        if let shareablePreviewWrapper = self.shareablePreviewWrapper {
            self.containerView.addSubview(shareablePreviewWrapper)
        }
    }
    
    internal func createConstraints() {
        constrain(self.view, self.blurView, self.containerView) { view, blurView, containerView in
            blurView.edges == view.edges
            containerView.edges == view.edges
        }
        
        if self.showPreview {
            let screenHeightCompact = (UIScreen.main.bounds.height <= 568)

            constrain(self.containerView, self.shareablePreviewWrapper!, self.shareablePreviewView!, self.tokenField) { view, shareablePreviewWrapper, shareablePreviewView, tokenField in
                
                shareablePreviewWrapper.top == view.top + 28
                shareablePreviewWrapper.left == view.left + 16
                shareablePreviewWrapper.right == -16 + view.right
                shareablePreviewWrapper.height <= (screenHeightCompact ? 150 : 200)
                
                shareablePreviewView.edges == shareablePreviewWrapper.edges
                
                tokenField.top == shareablePreviewWrapper.bottom + 16
            }
        }
        else {
            constrain(self.containerView, self.tokenField) { view, tokenField in
                tokenField.top == view.top + 28
            }
        }
        
        constrain(self.tokenField, self.searchIcon) { tokenField, searchIcon in
            searchIcon.centerY == tokenField.centerY
            searchIcon.left == tokenField.left + 5.5 // the search icon glyph has whitespaces
        }
        
        constrain(self.view, self.destinationsTableView, self.topSeparatorView) { view, destinationsTableView, topSeparatorView in
            topSeparatorView.left == view.left
            topSeparatorView.right == view.right
            topSeparatorView.top == destinationsTableView.top
            topSeparatorView.height == 0.5
        }
        
        
        constrain(self.containerView, self.destinationsTableView, self.tokenField, self.bottomSeparatorLine) { view, tableView, tokenField, bottomSeparatorLine in
            
            tokenField.left == view.left + 8
            tokenField.right == -8 + view.right
            tokenField.height >= 32
            
            tableView.left == view.left
            tableView.right == view.right
            tableView.top == tokenField.bottom + 8
            tableView.bottom == bottomSeparatorLine.top
            
            bottomSeparatorLine.left == view.left
            bottomSeparatorLine.right == view.right
            bottomSeparatorLine.height == 0.5
        }
        
        constrain(self.containerView, self.closeButton, self.sendButton, self.bottomSeparatorLine) { view, closeButton, sendButton, bottomSeparatorLine in
            
            closeButton.left == view.left
            closeButton.centerY == sendButton.centerY
            closeButton.width == 44
            closeButton.height == closeButton.width
            
            sendButton.top == bottomSeparatorLine.bottom + 12
            sendButton.height == 32
            sendButton.width == sendButton.height
            sendButton.centerX == view.centerX
            sendButton.bottom == -12 + view.bottom
        }
    }
}
