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

    func createShareablePreview() {
        let shareablePreviewView = self.shareable.previewView()
        shareablePreviewView?.layer.cornerRadius = 4
        shareablePreviewView?.clipsToBounds = true
        self.shareablePreviewView = shareablePreviewView

        let shareablePreviewWrapper = UIView()
        shareablePreviewWrapper.clipsToBounds = false
        shareablePreviewWrapper.layer.shadowOpacity = 1
        shareablePreviewWrapper.layer.shadowRadius = 8
        shareablePreviewWrapper.layer.shadowOffset = CGSize(width: 0, height: 8)
        shareablePreviewWrapper.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor

        shareablePreviewWrapper.addSubview(shareablePreviewView!)
        self.shareablePreviewWrapper = shareablePreviewWrapper

        self.shareablePreviewWrapper?.isHidden = !showPreview
    }

    internal func createViews() {
        
        createShareablePreview()

        self.tokenField.textColor = .white
        self.tokenField.clipsToBounds = true
        self.tokenField.layer.cornerRadius = 4
        self.tokenField.tokenTitleColor = UIColor.from(scheme: .textForeground, variant: .dark)
        self.tokenField.tokenSelectedTitleColor = UIColor.from(scheme: .textForeground, variant: .dark)
        self.tokenField.tokenTitleVerticalAdjustment = 1
        self.tokenField.textView.placeholderTextAlignment = .natural
        self.tokenField.textView.accessibilityIdentifier = "textViewSearch"
        self.tokenField.textView.placeholder = "content.message.forward.to".localized.uppercased()
        self.tokenField.textView.keyboardAppearance = .dark
        self.tokenField.textView.returnKeyType = .done
        self.tokenField.textView.autocorrectionType = .no
        self.tokenField.textView.textContainerInset = UIEdgeInsets(top: 9, left: 40, bottom: 11, right: 12)
        self.tokenField.textView.backgroundColor = UIColor.from(scheme: .tokenFieldBackground, variant: .dark)
        self.tokenField.delegate = self

        self.destinationsTableView.backgroundColor = .clear
        self.destinationsTableView.register(ShareDestinationCell<D>.self, forCellReuseIdentifier: ShareDestinationCell<D>.reuseIdentifier)
        self.destinationsTableView.separatorStyle = .none
        self.destinationsTableView.allowsSelection = true
        self.destinationsTableView.allowsMultipleSelection = self.allowsMultipleSelection
        self.destinationsTableView.keyboardDismissMode = .interactive
        self.destinationsTableView.delegate = self
        self.destinationsTableView.dataSource = self

        self.closeButton.accessibilityLabel = "close"
        self.closeButton.setIcon(.X, with: .tiny, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)

        self.sendButton.accessibilityLabel = "send"
        self.sendButton.isEnabled = false
        self.sendButton.setIcon(.send, with: .tiny, for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor.white, for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor(white: 0.64, alpha: 1), for: .disabled)
        self.sendButton.setBorderColor(.clear, for: .normal)
        self.sendButton.setBorderColor(.clear, for: .disabled)
        self.sendButton.circular = true
        self.sendButton.addTarget(self, action: #selector(ShareViewController.onSendButtonPressed(sender:)), for: .touchUpInside)

        if self.allowsMultipleSelection {
            self.searchIcon.image = UIImage(for: .search, iconSize: .tiny, color: .white)
        }
        else {
            self.searchIcon.isHidden = true
            self.sendButton.isHidden = true
            self.closeButton.isHidden = true
            self.bottomSeparatorLine.isHidden = true
        }

        [self.blurView, self.containerView].forEach(self.view.addSubview)
        [self.tokenField, self.destinationsTableView, self.closeButton, self.sendButton, self.bottomSeparatorLine, self.topSeparatorView, self.searchIcon].forEach(self.containerView.addSubview)
        
        if let shareablePreviewWrapper = self.shareablePreviewWrapper {
            self.containerView.addSubview(shareablePreviewWrapper)
        }
    }
    
    internal func createConstraints() {
        constrain(self.view, self.blurView, self.containerView) { view, blurView, containerView in
            blurView.edges == view.edges
            containerView.top == view.topMargin
            self.bottomConstraint = containerView.bottom == view.bottomMargin
            containerView.leading == view.leading
            containerView.trailing == view.trailing
        }
        
        constrain(self.containerView, self.shareablePreviewWrapper!, self.shareablePreviewView!, self.tokenField) { view, shareablePreviewWrapper, shareablePreviewView, tokenField in

            shareablePreviewTopConstraint = shareablePreviewWrapper.top == view.topMargin + 8
            shareablePreviewWrapper.left == view.left + 16
            shareablePreviewWrapper.right == -16 + view.right
            shareablePreviewView.edges == shareablePreviewWrapper.edges

            tokenFieldShareablePreviewSpacingConstraint = tokenField.top == shareablePreviewWrapper.bottom + 16

            tokenFieldTopConstraint = tokenField.top == view.top + 8
        }

        updateShareablePreviewConstraint()

        constrain(self.tokenField, self.searchIcon) { tokenField, searchIcon in
            searchIcon.centerY == tokenField.centerY
            searchIcon.left == tokenField.left + 8 // the search icon glyph has whitespaces
            if !self.allowsMultipleSelection {
                tokenField.height == 0
            }
        }
        
        constrain(self.view, self.destinationsTableView, self.topSeparatorView) { view, destinationsTableView, topSeparatorView in
            topSeparatorView.left == view.left
            topSeparatorView.right == view.right
            topSeparatorView.top == destinationsTableView.top
            topSeparatorView.height == .hairline
        }
        
        
        constrain(self.containerView, self.destinationsTableView, self.tokenField, self.bottomSeparatorLine) { view, tableView, tokenField, bottomSeparatorLine in
            
            tokenField.left == view.left + 8
            tokenField.right == -8 + view.right
            tokenField.height >= 40
            
            tableView.left == view.left
            tableView.right == view.right
            tableView.top == tokenField.bottom + 8
            tableView.bottom == bottomSeparatorLine.top
            
            bottomSeparatorLine.left == view.left
            bottomSeparatorLine.right == view.right
            bottomSeparatorLine.height == .hairline
        }
        
        if self.allowsMultipleSelection {
            constrain(self.containerView, self.closeButton, self.sendButton, self.bottomSeparatorLine) { view, closeButton, sendButton, bottomSeparatorLine in
                
                closeButton.leading == view.leading
                closeButton.centerY == sendButton.centerY
                closeButton.width == 44
                closeButton.height == closeButton.width
                
                sendButton.top == bottomSeparatorLine.bottom + 12
                sendButton.height == 32
                sendButton.width == sendButton.height
                sendButton.trailing == view.trailing - 16
                sendButton.bottom == -12 + view.bottom
            }
        }
        else {
            constrain(self.containerView, self.bottomSeparatorLine) { containerView, bottomSeparatorLine in
                bottomSeparatorLine.bottom == containerView.bottom
            }
        }
    }

}
