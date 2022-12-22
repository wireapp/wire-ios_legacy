//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import UIKit
import WireDataModel
import WireSyncEngine
import avs

protocol CallInfoConfigurationObserver: AnyObject {
    func didUpdateConfiguration(configuration: CallInfoConfiguration)
}

class CallingBottomSheetViewController: BottomSheetContainerViewController {
    private let bottomSheetMaxHeight = UIScreen.main.bounds.height * 0.7

    weak var delegate: ActiveCallViewControllerDelegate?
    private var participantsObserverToken: Any?
    private let voiceChannel: VoiceChannel
    private let headerBar = CallHeaderBar()

    var bottomSheetMinimalOffset: CGFloat {
        switch voiceChannel.state {
        case .incoming(degradedUser: _):
            return 230.0
        default:
            return 124.0
        }
    }

    let callingActionsInfoViewController: CallingActionsInfoViewController
    var visibleVoiceChannelViewController: CallViewController{
        didSet {
            transition(to: visibleVoiceChannelViewController, from: oldValue)
        }
    }

    init(voiceChannel: VoiceChannel) {
        self.voiceChannel = voiceChannel
        let selfUser: UserType = ZMUser.selfUser()
        visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel, selfUser: selfUser, isOverlayEnabled: false)

        callingActionsInfoViewController = CallingActionsInfoViewController(participants: voiceChannel.getParticipantsList(), selfUser: selfUser)
        super.init(contentViewController: visibleVoiceChannelViewController, bottomSheetViewController: callingActionsInfoViewController, bottomSheetConfiguration: .init(height: bottomSheetMaxHeight, initialOffset: 124.0))

        callingActionsInfoViewController.actionsDelegate = visibleVoiceChannelViewController
        callingActionsInfoViewController.actionsView.bottomSheetScrollingDelegate = self
        visibleVoiceChannelViewController.configurationObserver = self
        participantsObserverToken = voiceChannel.addParticipantObserver(self)
        visibleVoiceChannelViewController.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(didChangeOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
        addTopBar()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addTopBar() {
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        NSLayoutConstraint.activate([
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 74),
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.bottomAnchor.constraint(equalTo: visibleVoiceChannelViewController.view.topAnchor).withPriority(.required)
        ])
        headerBar.setTitle(title: voiceChannel.conversation?.displayName ?? "")
        headerBar.minimalizeButton.addTarget(self, action: #selector(hideCallView), for: .touchUpInside)
    }

    @objc private func didChangeOrientation() {
        if UIDevice.current.orientation.isLandscape {
            let newConfiguration = BottomSheetConfiguration(height: view.bounds.height, initialOffset: bottomSheetMinimalOffset)
            self.configuration = newConfiguration
        } else {
            let newConfiguration = BottomSheetConfiguration(height: bottomSheetMaxHeight, initialOffset: bottomSheetMinimalOffset)
            self.configuration = newConfiguration
        }
        hideBottomSheet()
    }

    override func didChangeState() {
        switch state {
        case .initial:
            visibleVoiceChannelViewController.view.accessibilityElementsHidden = false
        case .full:
            visibleVoiceChannelViewController.view.accessibilityElementsHidden = true
        }
    }

    func transition(to toViewController: UIViewController, from fromViewController: UIViewController) {
        guard toViewController != fromViewController else { return }
        toViewController.view.frame = view.bounds
        toViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addChild(toViewController)

        transition(from: fromViewController,
                   to: toViewController,
                   duration: 0.35,
                   options: .transitionCrossDissolve,
                   animations: nil,
                   completion: { _ in
                toViewController.didMove(toParent: self)
                fromViewController.removeFromParent()
        })
    }

    func updateVisibleVoiceChannelViewController() {
        guard let conversation = ZMUserSession.shared()?.priorityCallConversation, visibleVoiceChannelViewController.conversation != conversation,
              let voiceChannel = conversation.voiceChannel else {
            return
        }
        visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel, selfUser: ZMUser.selfUser())
        visibleVoiceChannelViewController.delegate = self
    }

}

extension CallingBottomSheetViewController: CallInfoConfigurationObserver {
    func didUpdateConfiguration(configuration: CallInfoConfiguration) {
        callingActionsInfoViewController.didUpdateConfiguration(configuration: configuration)
        panGesture.isEnabled = !configuration.state.isIncoming
        guard self.configuration.initialOffset != bottomSheetMinimalOffset else { return }
        let newConfiguration = BottomSheetConfiguration(height: bottomSheetMaxHeight, initialOffset: bottomSheetMinimalOffset)
        self.configuration = newConfiguration
        hideBottomSheet()
    }
}

extension CallingBottomSheetViewController: WireCallCenterCallParticipantObserver {
    func callParticipantsDidChange(conversation: ZMConversation, participants: [CallParticipant]) {
        callingActionsInfoViewController.participants = voiceChannel.getParticipantsList()
    }
}

extension CallingBottomSheetViewController: WireCallCenterCallStateObserver {
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateVisibleVoiceChannelViewController()
    }
}

extension CallingBottomSheetViewController: CallViewControllerDelegate {
    func callViewControllerDidDisappear(_ callController: CallViewController,
                                        for conversation: ZMConversation?) {
        delegate?.activeCallViewControllerDidDisappear(self, for: conversation)
    }

    @objc func hideCallView() {
        delegate?.activeCallViewControllerDidDisappear(self, for: voiceChannel.conversation)
    }
}

extension CallingBottomSheetViewController: BottomSheetScrollingDelegate {
    var isBottomSheetExpanded: Bool {
        return state == .full
    }

    func toggleBottomSheetVisibility() {
        switch state {
        case .full:
            hideBottomSheet(animated: false)
        case .initial:
            showBottomSheet(animated: false)
        }
    }
}


extension VoiceChannel {
    fileprivate func getParticipantsList() -> CallParticipantsList {
        let sortedParticipants = participants(ofKind: .all, activeSpeakersLimit: CallInfoConfiguration.maxActiveSpeakers).filter(\.state.isConnected)
        return sortedParticipants.map {
            CallParticipantsListCellConfiguration.callParticipant(user: HashBox(value: $0.user),
                             videoState: $0.state.videoState,
                             microphoneState: $0.state.microphoneState,
                             activeSpeakerState: $0.activeSpeakerState)
        }
    }
}
