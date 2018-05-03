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

// TODO: Do we need this or should the adapting be done in CallInfoViewControllerInput or even on a higher level?
//extension CallProperties {
//    func configuration(variant: ColorSchemeVariant) -> CallStatusViewInputType {
//        return .init(
//            state: configurationState,
//            isVideoCall: isVideoCall,
//            variant: variant,
//            isConstantBitRate: isConstantBitRateAudioActive,
//            title: conversation?.displayName ?? ""
//        )
//    }
//    
//    private var configurationState: CallStatusViewState {
//        // TODO: Add case returning .reconnecting?
//        switch state {
//        case .terminating: return .terminating
//        case .incoming: return .ringingIncoming(name: initiator?.displayName ?? "") // TODO
//        case .outgoing: return .ringingOutgoing
//        case .answered, .establishedDataChannel: return .connecting
//        case .established: return .established(duration: duration)
//        case .none, .unknown: return .none
//        }
//    }
//    
//    var duration: TimeInterval {
//        if let callStartDate = conversation?.voiceChannel?.callStartDate {
//            return -callStartDate.timeIntervalSinceNow
//        } else {
//            return 0
//        }
//    }
//}

final class CallStatusViewController: UIViewController {
    
    var configuration: CallStatusViewInputType {
        didSet {
            updateState()
        }
    }
    
    private let statusView: CallStatusView
    private weak var callDurationTimer: Timer?
    
    init(configuration: CallStatusViewInputType) {
        self.configuration = configuration
        statusView = CallStatusView(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
    }
    
    deinit {
        stopCallDurationTimer()
    }
    
    private func setupViews() {
        view.addSubview(statusView)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusView.topAnchor.constraint(equalTo: view.topAnchor),
            statusView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    private func updateState() {
        switch configuration.state {
        case .established: startCallDurationTimer()
        case .terminating: stopCallDurationTimer()
        default: break
        }
    }
    
    private func startCallDurationTimer() {
        stopCallDurationTimer()
        callDurationTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 0.1, repeats: true) { [statusView, configuration] _ in
            statusView.configuration = configuration
        }
    }
    
    private func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
}
