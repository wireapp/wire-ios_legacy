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

extension ConversationInputBarViewController {

    @objc
    func createInputBar() {
        audioButton = IconButton()
        audioButton.hitAreaPadding = CGSize.zero
        audioButton.accessibilityIdentifier = "audioButton"
        audioButton.setIconColor(UIColor.accent(), for: UIControl.State.selected)

        videoButton = IconButton()
        videoButton.hitAreaPadding = CGSize.zero
        videoButton.accessibilityIdentifier = "videoButton"

        photoButton = IconButton()
        photoButton.hitAreaPadding = CGSize.zero
        photoButton.accessibilityIdentifier = "photoButton"
        photoButton.setIconColor(UIColor.accent(), for: UIControl.State.selected)

        uploadFileButton = IconButton()
        uploadFileButton.hitAreaPadding = CGSize.zero
        uploadFileButton.accessibilityIdentifier = "uploadFileButton"

        sketchButton = IconButton()
        sketchButton.hitAreaPadding = CGSize.zero
        sketchButton.accessibilityIdentifier = "sketchButton"

        pingButton = IconButton()
        pingButton.hitAreaPadding = CGSize.zero
        pingButton.accessibilityIdentifier = "pingButton"

        locationButton = IconButton()
        locationButton.hitAreaPadding = CGSize.zero
        locationButton.accessibilityIdentifier = "locationButton"

        gifButton = IconButton()
        gifButton.hitAreaPadding = CGSize.zero
        gifButton.accessibilityIdentifier = "gifButton"

        mentionButton = IconButton()
        mentionButton.hitAreaPadding = CGSize.zero
        mentionButton.accessibilityIdentifier = "mentionButton"

        inputBar = InputBar(buttons: [
            photoButton,
            mentionButton,
            sketchButton,
            gifButton,
            audioButton,
            pingButton,
            uploadFileButton,
            locationButton,
            videoButton
            ])
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.delegate = self
        registerForTextFieldSelectionChange()

        view.addSubview(inputBar)

        let constraints: [NSLayoutConstraint] = []

        constraints += inputBar.fitInSuperview(exclude: [.bottom], activate: false).values

        let bottomConstraint = inputBar.pinToSuperview(anchor: .bottom )
        bottomConstraint.priority = .defaultLow

        constraints.append(bottomConstraint)

        NSLayoutConstraint.activate(constraints)

        inputBar.editingView.delegate = self
    }

}
