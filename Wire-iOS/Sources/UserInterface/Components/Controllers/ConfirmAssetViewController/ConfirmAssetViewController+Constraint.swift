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

    @objc func createConstraints() {
        topPanel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        imageToolbarView?.translatesAutoresizingMaskIntoConstraints = false
        imageToolbarSeparatorView?.translatesAutoresizingMaskIntoConstraints = false
        confirmButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        acceptImageButton.translatesAutoresizingMaskIntoConstraints = false
        rejectImageButton.translatesAutoresizingMaskIntoConstraints = false
        imagePreviewView?.translatesAutoresizingMaskIntoConstraints = false
        playerViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        imageToolbarViewInsideImage?.translatesAutoresizingMaskIntoConstraints = false

        acceptImageButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rejectImageButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let margin: CGFloat = 24

        // Base constraints for all cases
        var constraints: [NSLayoutConstraint] = [
            // contentLayoutGuide
            contentLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentLayoutGuide.topAnchor.constraint(equalTo: topPanel.bottomAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor),

            // topPanel
            topPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPanel.topAnchor.constraint(equalTo: safeTopAnchor),
            topPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPanel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            // titleLabel
            titleLabel.leadingAnchor.constraint(equalTo: topPanel.leadingAnchor, constant: margin),
            titleLabel.topAnchor.constraint(equalTo: topPanel.topAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: topPanel.trailingAnchor, constant: -margin),
            titleLabel.bottomAnchor.constraint(greaterThanOrEqualTo: topPanel.bottomAnchor, constant: -4),

            // bottomPanel
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            bottomPanel.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -margin),

            // confirmButtonsStack
            confirmButtonsStack.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
            confirmButtonsStack.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
            confirmButtonsStack.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),

            // confirmButtons
            acceptImageButton.heightAnchor.constraint(equalToConstant: 48),
            rejectImageButton.heightAnchor.constraint(equalToConstant: 48)
        ]

        // Image Toolbar
        if let toolbar = imageToolbarView {
            constraints += [
                // toolbar
                toolbar.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
                toolbar.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
                toolbar.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: 48),

                // buttons
                confirmButtonsStack.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: margin),
            ]

            // Separator
            if let toolbarSeparator = imageToolbarSeparatorView {
                constraints += [
                    toolbarSeparator.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
                    toolbarSeparator.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
                    toolbarSeparator.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
                    toolbarSeparator.heightAnchor.constraint(equalToConstant: 0.5)
                ]
            }
        } else {
            constraints += [
                confirmButtonsStack.topAnchor.constraint(equalTo: bottomPanel.topAnchor)
            ]
        }

        // Preview Image
        if let imagePreviewView = imagePreviewView {
            let imageSize: CGSize = image?.size ?? CGSize(width: 1, height: 1)

            constraints += [
                // dimension
                imagePreviewView.heightAnchor.constraint(equalTo: imagePreviewView.widthAnchor, multiplier: imageSize.height / imageSize.width),

                // centering
                imagePreviewView.centerXAnchor.constraint(equalTo: contentLayoutGuide.centerXAnchor),
                imagePreviewView.centerYAnchor.constraint(equalTo: contentLayoutGuide.centerYAnchor),

                // limits
                imagePreviewView.leadingAnchor.constraint(greaterThanOrEqualTo: contentLayoutGuide.leadingAnchor),
                imagePreviewView.topAnchor.constraint(greaterThanOrEqualTo: contentLayoutGuide.topAnchor, constant: margin),
                imagePreviewView.trailingAnchor.constraint(lessThanOrEqualTo: contentLayoutGuide.trailingAnchor),
                imagePreviewView.bottomAnchor.constraint(lessThanOrEqualTo: contentLayoutGuide.bottomAnchor, constant: -margin),
            ]

            // Image Toolbar Inside Image
            if let imageToolbarViewInsideImage = imageToolbarViewInsideImage {
                constraints += [
                    imageToolbarViewInsideImage.leadingAnchor.constraint(equalTo: imagePreviewView.leadingAnchor),
                    imageToolbarViewInsideImage.trailingAnchor.constraint(equalTo: imagePreviewView.trailingAnchor),
                    imageToolbarViewInsideImage.bottomAnchor.constraint(equalTo: imagePreviewView.bottomAnchor),
                    imageToolbarViewInsideImage.heightAnchor.constraint(equalToConstant: 48)
                ]
            }
        }

        // Player View
        if let playerView = playerViewController?.view {
            constraints += [
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: -margin),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -margin)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }
}
