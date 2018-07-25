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

protocol CallTopOverlayControllerDelegate: class {
    func voiceChannelTopOverlayWantsToRestoreCall(_ controller: CallTopOverlayController)
}

extension CallState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .incoming(_, _, _):
            return "call.status.incoming".localized
        case .outgoing(_):
            return "call.status.outgoing".localized
        case .answered(_), .establishedDataChannel:
            return "call.status.connecting".localized
        case .terminating(_):
            return "call.status.terminating".localized
        default:
            return ""
        }
    }
}

final class CallTopOverlayController: UIViewController {
    private let durationLabel = UILabel()
    
    class TapableAccessibleView: UIView {
        let onAccessibilityActivate: ()->()
        
        init(onAccessibilityActivate: @escaping ()->()) {
            self.onAccessibilityActivate = onAccessibilityActivate
            super.init(frame: .zero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func accessibilityActivate() -> Bool {
            onAccessibilityActivate()
            return true
        }
    }
    
    private let interactiveView = UIView()
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private weak var callDurationTimer: Timer? = nil
    private var observerToken: Any? = nil
    private let callDurationFormatter = DateComponentsFormatter()
    
    let conversation: ZMConversation
    weak var delegate: CallTopOverlayControllerDelegate? = nil
    
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
        
        self.observerToken = self.conversation.voiceChannel?.addCallStateObserver(self)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
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
        view.backgroundColor = UIColor(for: .strongLimeGreen)
        view.accessibilityIdentifier = "OpenOngoingCallButton"
        view.shouldGroupAccessibilityChildren = true
        view.isAccessibilityElement = true
        view.accessibilityLabel = "voice.top_overlay.accessibility_title".localized
        view.accessibilityTraits = UIAccessibilityTraitButton
        
        interactiveView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(interactiveView)
        
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        interactiveView.addSubview(durationLabel)
        durationLabel.font = FontSpec(.small, .semibold).font
        durationLabel.textColor = .white
        
        NSLayoutConstraint.activate([
            interactiveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactiveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactiveView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            interactiveView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.safeArea.top),
            durationLabel.centerXAnchor.constraint(equalTo: interactiveView.centerXAnchor),
            durationLabel.centerYAnchor.constraint(equalTo: interactiveView.centerYAnchor),
            interactiveView.heightAnchor.constraint(equalToConstant: 32)
            ])
        
        interactiveView.addGestureRecognizer(tapGestureRecognizer)
        
        updateLabel()
        (conversation.voiceChannel?.state).map(updateCallDurationTimer)
    }
    
    fileprivate func updateCallDurationTimer(for callState: CallState) {
        switch callState {
        case .established:
            startCallDurationTimer()
        case .terminating:
            stopCallDurationTimer()
        default:
            updateLabel()
            break
        }
    }
    
    private func startCallDurationTimer() {
        stopCallDurationTimer()
        
        callDurationTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 0.1, repeats: true) {
            [weak self] _ in
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
        durationLabel.text = statusString.uppercased()
        view.accessibilityValue = durationLabel.text
    }
    
    private var statusString: String {
        guard let state = conversation.voiceChannel?.state else {
            return ""
        }
        
        switch state {
        case .established, .establishedDataChannel:
            let duration = callDurationFormatter.string(from: callDuration) ?? ""
            
            return "voice.top_overlay.tap_to_return".localized + "   " + duration
        default:
            return state.description
        }
    }
    
    func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
    
    @objc dynamic func openCall(_ sender: UITapGestureRecognizer?) {
        delegate?.voiceChannelTopOverlayWantsToRestoreCall(self)
    }
}

extension CallTopOverlayController: WireCallCenterCallStateObserver {
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) {
        updateCallDurationTimer(for: callState)
    }
}
