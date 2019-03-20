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
            videoButton])

        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.textView.delegate = self
        registerForTextFieldSelectionChange()

        view.addSubview(inputBar)

        var constraints: [NSLayoutConstraint] = []

        constraints += inputBar.fitInSuperview(exclude: [.bottom], activate: false).values

        let bottomConstraint = inputBar.pinToSuperview(anchor: .bottom )
        bottomConstraint.priority = .defaultLow

        constraints.append(bottomConstraint)

        NSLayoutConstraint.activate(constraints)

        inputBar.editingView.delegate = self
    }

    @objc
    func createEphemeralIndicatorButton() {
        ephemeralIndicatorButton = IconButton()
        ephemeralIndicatorButton.layer.borderWidth = 0.5

        ephemeralIndicatorButton.accessibilityIdentifier = "ephemeralTimeIndicatorButton"
        ephemeralIndicatorButton.adjustsTitleWhenHighlighted = true
        ephemeralIndicatorButton.adjustsBorderColorWhenHighlighted = true

        inputBar.rightAccessoryStackView.insertArrangedSubview(ephemeralIndicatorButton, at: 0)

        ephemeralIndicatorButton.setDimensions(length: InputBar.rightIconSize)

        ephemeralIndicatorButton.setTitleColor(UIColor.lightGraphite, for: .disabled)
        ephemeralIndicatorButton.setTitleColor(UIColor.accent(), for: .normal)

        updateEphemeralIndicatorButtonTitle(ephemeralIndicatorButton)
    }

    @objc
    func createEmojiButton() {
        let senderDiameter: CGFloat = 28

        emojiButton = IconButton(style: .circular)
        emojiButton.accessibilityIdentifier = "emojiButton"

        inputBar.leftAccessoryView.addSubview(emojiButton)

        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        emojiButton.pinToSuperview(axisAnchor: .centerX)
        emojiButton.pinToSuperview(anchor: .bottom, inset: 14)
        emojiButton.setDimensions(length: senderDiameter)
    }

    @objc
    func createMarkdownButton() {
        let senderDiameter: CGFloat = 28

        markdownButton = IconButton(style: .circular)
        markdownButton.accessibilityIdentifier = "markdownButton"
        inputBar.leftAccessoryView.addSubview(markdownButton)

        markdownButton.translatesAutoresizingMaskIntoConstraints = false
        markdownButton.pinToSuperview(axisAnchor: .centerX)
        markdownButton.pinToSuperview(anchor: .bottom, inset: 14)
        markdownButton.setDimensions(length: senderDiameter)
    }

    @objc
    func createHourglassButton() {
        hourglassButton = IconButton(style: .default)
        hourglassButton.translatesAutoresizingMaskIntoConstraints = false

        hourglassButton.setIcon(.hourglass, with: .tiny, for: UIControl.State.normal)

        hourglassButton.accessibilityIdentifier = "ephemeralTimeSelectionButton"
        inputBar.rightAccessoryStackView.addArrangedSubview(hourglassButton)

        hourglassButton.setDimensions(length: InputBar.rightIconSize)
    }

    @objc
    func createTypingIndicatorView() {
        typingIndicatorView = TypingIndicatorView()
        typingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        typingIndicatorView.accessibilityIdentifier = "typingIndicator"
        typingIndicatorView.typingUsers = (Array(typingUsers ?? []) as? [ZMUser]) ?? []
        typingIndicatorView.setHidden(true, animated: false)

        inputBar.addSubview(typingIndicatorView)

        var constraints = [NSLayoutConstraint]()
        constraints.append(typingIndicatorView.centerYAnchor.constraint(equalTo: inputBar.topAnchor))

        constraints.append(typingIndicatorView.pinToSuperview(axisAnchor: .centerX, activate: false))

        constraints.append(typingIndicatorView.leftAnchor.constraint(greaterThanOrEqualTo: typingIndicatorView.superview!.leftAnchor, constant: 48))
        constraints.append(typingIndicatorView.rightAnchor.constraint(greaterThanOrEqualTo: typingIndicatorView.superview!.rightAnchor, constant: 48))

        NSLayoutConstraint.activate(constraints)
    }

}
