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
        
        self.shareablePreviewView = self.shareable.previewView()
        self.shareablePreviewView.isUserInteractionEnabled = false
        self.shareablePreviewView.layer.cornerRadius = 4
        self.shareablePreviewView.clipsToBounds = true
        
        self.shareablePreviewWrapper = UIView()
        self.shareablePreviewWrapper.clipsToBounds = false
        self.shareablePreviewWrapper.layer.shadowOpacity = 1
        self.shareablePreviewWrapper.layer.shadowRadius = 8
        self.shareablePreviewWrapper.layer.shadowOffset = CGSize(width: 0, height: 8)
        self.shareablePreviewWrapper.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor
        self.shareablePreviewWrapper.layer.shadowPath = UIBezierPath(rect: self.shareablePreviewView.bounds).cgPath
        
        self.shareablePreviewWrapper.addSubview(self.shareablePreviewView)
        
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
        
        self.closeButton = IconButton()
        self.closeButton.accessibilityLabel = "close"
        self.closeButton.cas_styleClass = "default-light"
        self.closeButton.setIcon(.X, with: .tiny, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)
        
        self.sendButton = IconButton()
        self.sendButton.accessibilityLabel = "send"
        self.sendButton.cas_styleClass = "default-dark"
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
        
        [self.blurView, self.shareablePreviewWrapper, self.tokenField, self.destinationsTableView, self.closeButton, self.sendButton, self.bottomSeparatorLine, self.topSeparatorView, self.searchIcon].forEach(self.view.addSubview)
    }
    
    
    internal func createConstraints() {
        constrain(self.view, self.blurView) { view, blurView in
            blurView.edges == view.edges
        }
        
        constrain(self.shareablePreviewWrapper, self.shareablePreviewView) { shareablePreviewWrapper, shareablePreviewView in
            shareablePreviewView.edges == shareablePreviewWrapper.edges
        }
        
        constrain(self.tokenField, self.searchIcon) { tokenField, searchIcon in
            searchIcon.centerY == tokenField.centerY
            searchIcon.left == tokenField.left + 3.5 // the search icon glyph has whitespaces
        }
        
        constrain(self.view, self.destinationsTableView, self.topSeparatorView) { view, destinationsTableView, topSeparatorView in
            topSeparatorView.left == view.left
            topSeparatorView.right == view.right
            topSeparatorView.top == destinationsTableView.top
            topSeparatorView.height == 0.5
        }
        
        let screenHeightCompact = (UIScreen.main.bounds.height <= 568)
        
        constrain(self.view, self.destinationsTableView, self.shareablePreviewWrapper, self.tokenField, self.bottomSeparatorLine) { view, tableView, shareablePreviewWrapper, tokenField, bottomSeparatorLine in
            
            shareablePreviewWrapper.top == view.top + 28
            shareablePreviewWrapper.left == view.left + 16
            shareablePreviewWrapper.right == -16 + view.right
            shareablePreviewWrapper.height <= (screenHeightCompact ? 150 : 200)
            
            tokenField.top == shareablePreviewWrapper.bottom + 16
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
        
        constrain(self.view, self.closeButton, self.sendButton, self.bottomSeparatorLine) { view, closeButton, sendButton, bottomSeparatorLine in
            
            closeButton.left == view.left
            closeButton.centerY == sendButton.centerY
            closeButton.width == 40
            closeButton.height == closeButton.width
            
            sendButton.top == bottomSeparatorLine.bottom + 12
            sendButton.height == 32
            sendButton.width == sendButton.height
            sendButton.centerX == view.centerX
            sendButton.bottom == -12 + view.bottom
        }
    }
}
