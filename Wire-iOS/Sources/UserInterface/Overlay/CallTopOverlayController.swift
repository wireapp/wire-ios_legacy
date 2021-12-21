//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireDataModel
import WireSyncEngine
import avs

protocol CallTopOverlayControllerDelegate: AnyObject {
    func voiceChannelTopOverlayWantsToRestoreCall(voiceChannel: VoiceChannel?)
}

extension CallState {
    public func description(callee: String, conversation: String, isGroup: Bool) -> String {
        switch self {
        case .incoming:
            let toAppend = (isGroup ? conversation + "・" : "")
            return toAppend + "call.status.incoming.user".localized(args: callee)
        case .outgoing:
            return "call.status.outgoing.user".localized(args: conversation)
        case .answered, .establishedDataChannel:
            return "call.status.connecting".localized
        case .terminating:
            return "call.status.terminating".localized
        default:
            return ""
        }
    }
}

final class CallTopOverlayController: UIViewController {
    private let durationLabel = UILabel()

    class TapableAccessibleView: UIView {
        let onAccessibilityActivate: () -> Void

        init(onAccessibilityActivate: @escaping () -> Void) {
            self.onAccessibilityActivate = onAccessibilityActivate
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func accessibilityActivate() -> Bool {
            onAccessibilityActivate()
            return true
        }
    }

    private let interactiveView = UIView()
    private let muteIcon = UIImageView()
    private var muteIconWidth: NSLayoutConstraint?
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private weak var callDurationTimer: Timer?
    private var observerTokens: [Any] = []
    private let callDurationFormatter = DateComponentsFormatter()

    let conversation: ZMConversation
    weak var delegate: CallTopOverlayControllerDelegate?

    private var callDuration: TimeInterval = 0 {
        didSet {
            updateLabel()
        }
    }

    deinit {
        stopCallDurationTimer()
    }

    init(conversation: ZMConversation) {
        self.conversation = conversation
        callDurationFormatter.allowedUnits = [.minute, .second]
        callDurationFormatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior(rawValue: 0)
        super.init(nibName: nil, bundle: nil)

        if let userSession = ZMUserSession.shared() {
            observerTokens.append(WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession))
            observerTokens.append(WireCallCenterV3.addMuteStateObserver(observer: self, userSession: userSession))
        }

    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func loadView() {
        view = TapableAccessibleView(onAccessibilityActivate: { [weak self] in
            self?.openCall(nil)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openCall(_:)))

        view.clipsToBounds = true
        view.backgroundColor = .strongLimeGreen
        view.accessibilityIdentifier = "OpenOngoingCallButton"
        view.shouldGroupAccessibilityChildren = true
        view.isAccessibilityElement = true
        view.accessibilityLabel = "voice.top_overlay.accessibility_title".localized
        view.accessibilityTraits = .button

        interactiveView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(interactiveView)

        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        interactiveView.addSubview(durationLabel)
        durationLabel.font = FontSpec(.small, .semibold).font
        durationLabel.textColor = .white
        durationLabel.lineBreakMode = .byTruncatingMiddle
        durationLabel.textAlignment = .center

        muteIcon.translatesAutoresizingMaskIntoConstraints = false
        interactiveView.addSubview(muteIcon)
        muteIconWidth = muteIcon.widthAnchor.constraint(equalToConstant: 0.0)
        displayMuteIcon = false

        NSLayoutConstraint.activate([
            interactiveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactiveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactiveView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            interactiveView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.safeArea.top),
            durationLabel.centerYAnchor.constraint(equalTo: interactiveView.centerYAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: muteIcon.trailingAnchor, constant: 8),
            durationLabel.trailingAnchor.constraint(equalTo: interactiveView.trailingAnchor, constant: -16),
            interactiveView.heightAnchor.constraint(equalToConstant: 32),
            muteIcon.leadingAnchor.constraint(equalTo: interactiveView.leadingAnchor, constant: 8),
            muteIcon.centerYAnchor.constraint(equalTo: interactiveView.centerYAnchor),
            muteIconWidth!
            ])

        interactiveView.addGestureRecognizer(tapGestureRecognizer)
        updateLabel()
        (conversation.voiceChannel?.state).map(updateCallDurationTimer)
    }

    private var displayMuteIcon: Bool = false {
        didSet {
            if displayMuteIcon {
                muteIcon.setIcon(.microphoneOff, size: 12, color: .white)
                muteIconWidth?.constant = 12
            } else {
                muteIcon.image = nil
                muteIconWidth?.constant = 0.0
            }
        }
    }

    fileprivate func updateCallDurationTimer(for callState: CallState) {
        switch callState {
        case .established:
            startCallDurationTimer()
        case .terminating:
            stopCallDurationTimer()
        default:
            updateLabel()
        }
    }

    private func startCallDurationTimer() {
        stopCallDurationTimer()

        callDurationTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCallDuration()
        }
    }

    private func updateCallDuration() {
        if let callStartDate = self.conversation.voiceChannel?.callStartDate {
            self.callDuration = -callStartDate.timeIntervalSinceNow
        } else {
            self.callDuration = 0
        }
    }

    private func updateLabel() {
        durationLabel.text = statusString.localizedUppercase
        view.accessibilityValue = durationLabel.text
    }

    private var statusString: String {
        guard let state = conversation.voiceChannel?.state else {
            return ""
        }

        switch state {
        case .established, .establishedDataChannel:
            let duration = callDurationFormatter.string(from: callDuration) ?? ""
            return "voice.top_overlay.tap_to_return".localized + "・" + duration
        default:
            let initiator = self.conversation.voiceChannel?.initiator?.name ?? ""
            let conversation = self.conversation.displayName
            return state.description(callee: initiator, conversation: conversation, isGroup: self.conversation.conversationType == .group)
        }
    }

    func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }

    @objc
    private func openCall(_ sender: UITapGestureRecognizer?) {
        delegate?.voiceChannelTopOverlayWantsToRestoreCall(voiceChannel: conversation.voiceChannel)
    }
}

extension CallTopOverlayController: WireCallCenterCallStateObserver {
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateCallDurationTimer(for: callState)
    }
}

extension CallTopOverlayController: MuteStateObserver {
    func callCenterDidChange(muted: Bool) {
        displayMuteIcon = muted
    }
}
