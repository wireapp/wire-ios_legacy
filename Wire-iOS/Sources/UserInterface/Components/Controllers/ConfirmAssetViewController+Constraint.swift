//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ConfirmAssetViewController {
    @objc
    func createConstraints() {
        [topPanel,
         titleLabel,
         bottomPanel,
         imageToolbarView,
         imageToolbarSeparatorView,
         confirmButtonsContainer,
         acceptImageButton,
         rejectImageButton,
         imagePreviewView,
         playerViewController?.view,
         imageToolbarViewInsideImage].forEach{$0?.translatesAutoresizingMaskIntoConstraints = false}
        
        let safeTopBarHeight = CGFloat(ConfirmAssetViewController.topBarHeight() + UIScreen.safeArea.top)
        
        // Top panel
        topPanel.fitInSuperview(exclude: [.bottom])
        topBarHeightConstraint = topPanel.heightAnchor.constraint(equalToConstant: safeTopBarHeight)
        topBarHeightConstraint.isActive = true

        titleLabel.pinToSuperview(anchor: .top, inset: UIScreen.safeArea.top)
        titleLabel.pinToSuperview(anchor: .bottom)
        titleLabel.pinToSuperview(axisAnchor: .centerX)
        
        // Bottom panel
        bottomPanel.fitInSuperview(with: EdgeInsets(edgeInsets: UIScreen.safeArea), exclude: [.top])
        
        imageToolbarView?.fitInSuperview(exclude: [.bottom])
        
        imageToolbarView?.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        imageToolbarSeparatorView?.fitInSuperview(exclude: [.top])
        imageToolbarSeparatorView?.heightAnchor.constraint(equalToConstant: 0.5).isActive = true


        confirmButtonsContainer.pinToSuperview(axisAnchor: .centerX)
        confirmButtonsContainer.pinToSuperview(anchor: .bottom)

        NSLayoutConstraint.activate([
            // Accept/Reject panel
            confirmButtonsContainer.leadingAnchor.constraint(greaterThanOrEqualTo: confirmButtonsContainer.superview!.leadingAnchor),
            confirmButtonsContainer.trailingAnchor.constraint(greaterThanOrEqualTo: confirmButtonsContainer.superview!.trailingAnchor),
            confirmButtonsContainer.heightAnchor.constraint(equalToConstant: ConfirmAssetViewController.bottomBarMinHeight())
            ])
        
        if let imageToolbarView = imageToolbarView {
            confirmButtonsContainer.topAnchor.constraint(equalTo: imageToolbarView.bottomAnchor).isActive = true
        } else {
            confirmButtonsContainer.pinToSuperview(anchor: .top)
        }
        
        acceptImageButton.pinToSuperview(axisAnchor: .centerY)
        acceptImageButton.pinToSuperview(anchor: .trailing, inset: ConfirmAssetViewController.marginInset())

        NSLayoutConstraint.activate([
            acceptImageButton.heightAnchor.constraint(equalToConstant: 40)])
        
        acceptImageButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        rejectImageButton.pinToSuperview(axisAnchor: .centerY)
        rejectImageButton.pinToSuperview(anchor: .leading, inset: ConfirmAssetViewController.marginInset())
        NSLayoutConstraint.activate([
            rejectImageButton.heightAnchor.constraint(equalToConstant: 40)])
        rejectImageButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        
        [acceptImageButton.widthAnchor.constraint(equalToConstant: 184),
         rejectImageButton.widthAnchor.constraint(equalToConstant: 184),
         acceptImageButton.leftAnchor.constraint(equalTo: rejectImageButton.rightAnchor, constant: 16)   ].forEach() {
            $0.priority = .defaultHigh
            $0.isActive = true
        }
        
        acceptImageButton.widthAnchor.constraint(equalTo: rejectImageButton.widthAnchor).isActive = true
        
        
        // Preview image
        if let imagePreviewView = imagePreviewView {
            let imageSize: CGSize = image?.size ?? CGSize(width: 1, height: 1)

            imagePreviewView.centerInSuperview()

            NSLayoutConstraint.activate([
                imagePreviewView.topAnchor.constraint(greaterThanOrEqualTo: topPanel.bottomAnchor),
                imagePreviewView.bottomAnchor.constraint(lessThanOrEqualTo: bottomPanel.topAnchor),
                imagePreviewView.rightAnchor.constraint(lessThanOrEqualTo: imagePreviewView.superview!.rightAnchor),
                imagePreviewView.leftAnchor.constraint(greaterThanOrEqualTo: imagePreviewView.superview!.leftAnchor),
                imagePreviewView.heightAnchor.constraint(equalTo: imagePreviewView.widthAnchor, multiplier: imageSize.height / imageSize.width)
                ])
        }
        
        if let playerView = playerViewController?.view {
            playerView.fitInSuperview(exclude: [.top, .bottom])
            NSLayoutConstraint.activate([playerView.topAnchor.constraint(equalTo: topPanel.bottomAnchor),
                                         playerView.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor)
                ])
        }
        
        if titleLabel.text != nil {
            topBarHeightConstraint.constant = safeTopBarHeight
        } else {
            topBarHeightConstraint.constant = 0
        }

        // Image toolbar
        if let imageToolbarViewInsideImage = imageToolbarViewInsideImage {
            imageToolbarViewInsideImage.fitInSuperview(exclude: [.top])
            
            
            imageToolbarViewInsideImage.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
    }
}
