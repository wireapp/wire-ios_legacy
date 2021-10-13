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
import UIKit
import WireCommonComponents

final class AudioButtonOverlay: UIView {

    enum AudioButtonOverlayButtonType {
        case play, send, stop
    }

    typealias ButtonPressHandler = (AudioButtonOverlayButtonType) -> Void

    var recordingState: AudioRecordState = .recording {
        didSet { updateWithRecordingState(recordingState) }
    }

    var playingState: PlayingState = .idle {
        didSet { updateWithPlayingState(playingState) }
    }

    fileprivate var heightConstraint: NSLayoutConstraint?
    fileprivate var widthConstraint: NSLayoutConstraint?

    let darkColor = UIColor.from(scheme: .textForeground)
    let brightColor = UIColor.from(scheme: .textBackground)
    let greenColor = UIColor.strongLimeGreen
    let grayColor = UIColor.from(scheme: .audioButtonOverlay)
    let superviewColor = UIColor.from(scheme: .background)

    let audioButton = IconButton()
    let playButton = IconButton()
    let sendButton = IconButton()
    let backgroundView = UIView()
    var buttonHandler: ButtonPressHandler?

    init() {
        super.init(frame: CGRect.zero)
        configureViews()
        createConstraints()
        updateWithRecordingState(recordingState)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = bounds.width / 2
    }

    func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        audioButton.isUserInteractionEnabled = false
        audioButton.setIcon(.microphone, size: .tiny, for: [])
        audioButton.accessibilityIdentifier = "audioRecorderRecord"

        playButton.setIcon(.play, size: .tiny, for: [])
        playButton.accessibilityIdentifier = "audioRecorderPlay"
        playButton.accessibilityValue = PlayingState.idle.description

        sendButton.setIcon(.checkmark, size: .tiny, for: [])
        sendButton.accessibilityIdentifier = "audioRecorderSend"

        [backgroundView, audioButton, sendButton, playButton].forEach(addSubview)

        playButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    func createConstraints() {
        let initialViewWidth: CGFloat = 40

        NSLayoutConstraint.activate([
          audioButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -initialViewWidth / 2),
          audioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

          playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          playButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -initialViewWidth / 2),

          sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          sendButton.centerYAnchor.constraint(equalTo: view.topAnchor, constant: initialViewWidth / 2),

          widthConstraint = view.widthAnchor.constraint(equalToConstant: initialViewWidth),
          heightConstraint = view.heightAnchor.constraint(equalToConstant: 96),
          backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
          backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          backgroundView.leftAnchor.constraint(equalTo: view.leftAnchor),
          backgroundView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    func setOverlayState(_ state: AudioButtonOverlayState) {
        defer { layoutIfNeeded() }
        heightConstraint?.constant = state.height
        widthConstraint?.constant = state.width
        alpha = state.alpha

        let blendedGray = grayColor.removeAlphaByBlending(with: superviewColor)
        sendButton.setIconColor(state.colorWithColors(greenColor, highlightedColor: brightColor), for: [])
        backgroundView.backgroundColor = state.colorWithColors(blendedGray, highlightedColor: greenColor)
        audioButton.setIconColor(state.colorWithColors(darkColor, highlightedColor: brightColor), for: [])
        playButton.setIconColor(darkColor, for: [])
    }

    func updateWithRecordingState(_ state: AudioRecordState) {
        audioButton.isHidden = state == .finishedRecording
        playButton.isHidden = state == .recording
        sendButton.isHidden = false
        backgroundView.isHidden = false
    }

    func updateWithPlayingState(_ state: PlayingState) {
        let icon: StyleKitIcon = state == .idle ? .play : .stopRecording
        playButton.setIcon(icon, size: .tiny, for: [])
        playButton.accessibilityValue = state.description
    }

    @objc func buttonPressed(_ sender: IconButton) {
        let type: AudioButtonOverlayButtonType

        if sender == sendButton {
            type = .send
        } else {
            type = playingState == .idle ? .play : .stop
        }

        buttonHandler?(type)
    }

}
