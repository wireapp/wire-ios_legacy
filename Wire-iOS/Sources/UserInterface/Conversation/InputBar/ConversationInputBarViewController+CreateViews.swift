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
    func setupViews() {
        createSendButton()
        createEphemeralIndicatorButton()
        createMarkdownButton()

        createHourglassButton()
        createTypingIndicatorView()

        createInputBar()

        inputBar.rightAccessoryStackView.addArrangedSubview(sendButton)
        inputBar.rightAccessoryStackView.insertArrangedSubview(ephemeralIndicatorButton, at: 0)
        inputBar.leftAccessoryView.addSubview(markdownButton)
        inputBar.rightAccessoryStackView.addArrangedSubview(hourglassButton)
        inputBar.addSubview(typingIndicatorView!)

        createConstraints()
    }

    private func createInputBar() {
        audioButton = IconButton()
        audioButton.accessibilityIdentifier = "audioButton"
        audioButton.setIconColor(UIColor.accent(), for: UIControl.State.selected)

        videoButton = IconButton()
        videoButton.accessibilityIdentifier = "videoButton"

        photoButton = IconButton()
        photoButton.accessibilityIdentifier = "photoButton"
        photoButton.setIconColor(UIColor.accent(), for: UIControl.State.selected)

        uploadFileButton = IconButton()
        uploadFileButton.accessibilityIdentifier = "uploadFileButton"

        sketchButton = IconButton()
        sketchButton.accessibilityIdentifier = "sketchButton"

        pingButton = IconButton()
        pingButton.accessibilityIdentifier = "pingButton"

        locationButton = IconButton()
        locationButton.accessibilityIdentifier = "locationButton"

        gifButton = IconButton()
        gifButton.accessibilityIdentifier = "gifButton"

        mentionButton = IconButton()
        mentionButton.accessibilityIdentifier = "mentionButton"

        let buttons: [IconButton] = [
            photoButton,
            mentionButton,
            sketchButton,
            gifButton,
            audioButton,
            pingButton,
            uploadFileButton,
            locationButton,
            videoButton]

        buttons.forEach(){ $0.hitAreaPadding = CGSize.zero }

        inputBar = InputBar(buttons: buttons)

        inputBar.textView.delegate = self
        registerForTextFieldSelectionChange()

        view.addSubview(inputBar)

        inputBar.editingView.delegate = self
    }

    private func createEphemeralIndicatorButton() {
        ephemeralIndicatorButton = IconButton()
        ephemeralIndicatorButton.layer.borderWidth = 0.5

        ephemeralIndicatorButton.accessibilityIdentifier = "ephemeralTimeIndicatorButton"
        ephemeralIndicatorButton.adjustsTitleWhenHighlighted = true
        ephemeralIndicatorButton.adjustsBorderColorWhenHighlighted = true



        ephemeralIndicatorButton.setTitleColor(UIColor.lightGraphite, for: .disabled)
        ephemeralIndicatorButton.setTitleColor(UIColor.accent(), for: .normal)

        updateEphemeralIndicatorButtonTitle(ephemeralIndicatorButton)
    }

    private func createMarkdownButton() {
        markdownButton = IconButton(style: .circular)
        markdownButton.accessibilityIdentifier = "markdownButton"
    }

    private func createHourglassButton() {
        hourglassButton = IconButton(style: .default)

        hourglassButton.setIcon(.hourglass, size: .tiny, for: UIControl.State.normal)

        hourglassButton.accessibilityIdentifier = "ephemeralTimeSelectionButton"
    }

    private func createTypingIndicatorView() {
        let typingIndicatorView = TypingIndicatorView()
        typingIndicatorView.accessibilityIdentifier = "typingIndicator"
        if let typingUsers = typingUsers,
            let typingUsersArray = Array(typingUsers) as? [ZMUser] {
            typingIndicatorView.typingUsers = typingUsersArray
        } else {
            typingIndicatorView.typingUsers = []
        }
        typingIndicatorView.setHidden(true, animated: false)

        self.typingIndicatorView = typingIndicatorView
    }

    private func createConstraints() {
        guard let typingIndicatorView = typingIndicatorView else { return }

        inputBar.translatesAutoresizingMaskIntoConstraints = false
        markdownButton.translatesAutoresizingMaskIntoConstraints = false
        hourglassButton.translatesAutoresizingMaskIntoConstraints = false
        typingIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        let bottomConstraint = inputBar.bottomAnchor.constraint(equalTo: inputBar.superview!.bottomAnchor)
        bottomConstraint.priority = .defaultLow

        let senderDiameter: CGFloat = 28

        NSLayoutConstraint.activate([
            inputBar.topAnchor.constraint(equalTo: inputBar.superview!.topAnchor),
            inputBar.leadingAnchor.constraint(equalTo: inputBar.superview!.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: inputBar.superview!.trailingAnchor),
            bottomConstraint,

            sendButton.widthAnchor.constraint(equalToConstant: InputBar.rightIconSize),
            sendButton.heightAnchor.constraint(equalToConstant: InputBar.rightIconSize),

            ephemeralIndicatorButton.widthAnchor.constraint(equalToConstant: InputBar.rightIconSize),
            ephemeralIndicatorButton.heightAnchor.constraint(equalToConstant: InputBar.rightIconSize),

            markdownButton.centerXAnchor.constraint(equalTo: markdownButton.superview!.centerXAnchor),
            markdownButton.bottomAnchor.constraint(equalTo: markdownButton.superview!.bottomAnchor, constant: -14),
            markdownButton.widthAnchor.constraint(equalToConstant: senderDiameter),
            markdownButton.heightAnchor.constraint(equalToConstant: senderDiameter),

            hourglassButton.widthAnchor.constraint(equalToConstant: InputBar.rightIconSize),
            hourglassButton.heightAnchor.constraint(equalToConstant: InputBar.rightIconSize),

            typingIndicatorView.centerYAnchor.constraint(equalTo: inputBar.topAnchor),
            typingIndicatorView.centerXAnchor.constraint(equalTo: typingIndicatorView.superview!.centerXAnchor),
            typingIndicatorView.leftAnchor.constraint(greaterThanOrEqualTo: typingIndicatorView.superview!.leftAnchor, constant: 48),
            typingIndicatorView.rightAnchor.constraint(lessThanOrEqualTo: typingIndicatorView.superview!.rightAnchor, constant: 48)
        ])
    }
}
