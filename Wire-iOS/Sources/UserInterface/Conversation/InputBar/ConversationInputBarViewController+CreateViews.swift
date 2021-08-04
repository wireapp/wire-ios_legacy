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
import UIKit
import WireSyncEngine

extension ConversationInputBarViewController {
    func setupViews() {
        updateEphemeralIndicatorButtonTitle(ephemeralIndicatorButton)

        setupInputBar()

        inputBar.rightAccessoryStackView.addArrangedSubview(sendButton)
        inputBar.rightAccessoryStackView.insertArrangedSubview(ephemeralIndicatorButton, at: 0)
        inputBar.leftAccessoryView.addSubview(markdownButton)
        inputBar.rightAccessoryStackView.addArrangedSubview(hourglassButton)
        inputBar.addSubview(typingIndicatorView)

        createConstraints()
    }

    var inputBarButtons: [IconButton] {
        return [canFilesBeShared ? photoButton : nil,
                mentionButton,
                canFilesBeShared ? sketchButton : nil,
                canFilesBeShared ? gifButton : nil,
                canFilesBeShared ? audioButton : nil,
                pingButton,
                canFilesBeShared ? uploadFileButton : nil,
                locationButton,
                canFilesBeShared ? videoButton : nil].compactMap { $0 }
    }

    private func setupInputBar() {
        audioButton.accessibilityIdentifier = "audioButton"
        videoButton.accessibilityIdentifier = "videoButton"
        photoButton.accessibilityIdentifier = "photoButton"
        uploadFileButton.accessibilityIdentifier = "uploadFileButton"
        sketchButton.accessibilityIdentifier = "sketchButton"
        pingButton.accessibilityIdentifier = "pingButton"
        locationButton.accessibilityIdentifier = "locationButton"
        gifButton.accessibilityIdentifier = "gifButton"
        mentionButton.accessibilityIdentifier = "mentionButton"
        markdownButton.accessibilityIdentifier = "markdownButton"

        inputBarButtons.forEach {
            $0.hitAreaPadding = .zero
        }

        inputBar.textView.delegate = self
        inputBar.textView.informalTextViewDelegate = self
        registerForTextFieldSelectionChange()

        view.addSubview(inputBar)

        inputBar.editingView.delegate = self
    }

    private func createConstraints() {
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

extension ConversationInputBarViewController {
    /// Whether files can be shared and received
    var canFilesBeShared: Bool {
        guard let session = ZMUserSession.shared() else { return true }
        return session.fileSharingFeature.status == .enabled
    }
}
