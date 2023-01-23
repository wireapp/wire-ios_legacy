//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSystem
import WireDataModel
import WireSyncEngine

private let zmLog = ZMSLog(tag: "calling")

protocol ActiveCallViewControllerDelegate: AnyObject {
    func activeCallViewControllerDidDisappear(_ activeCallViewController: UIViewController,
                                              for conversation: ZMConversation?)
}

/// ViewController container for CallViewControllers. Displays the active the controller for active or incoming calls.
final class ActiveCallViewController: UIViewController {

    weak var delegate: ActiveCallViewControllerDelegate?

    var callStateObserverToken: Any?

    init(voiceChannel: VoiceChannel) {
        visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel, selfUser: ZMUser.selfUser())

        super.init(nibName: nil, bundle: nil)

        addChild(visibleVoiceChannelViewController)

        visibleVoiceChannelViewController.view.frame = view.bounds
        visibleVoiceChannelViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(visibleVoiceChannelViewController.view)
        visibleVoiceChannelViewController.didMove(toParent: self)

        zmLog.debug(String(format: "Presenting CallViewController: %p", visibleVoiceChannelViewController))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var visibleVoiceChannelViewController: CallViewController {
        didSet {
            transition(to: visibleVoiceChannelViewController, from: oldValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let userSession = ZMUserSession.shared() else {
            zmLog.error("UserSession not available when initializing \(type(of: self))")
            return
        }

        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        visibleVoiceChannelViewController.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateVisibleVoiceChannelViewController()
    }

    override var childForStatusBarStyle: UIViewController? {
        return visibleVoiceChannelViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return visibleVoiceChannelViewController
    }

    func updateVisibleVoiceChannelViewController() {
        guard let conversation = ZMUserSession.shared()?.priorityCallConversation, visibleVoiceChannelViewController.conversation != conversation,
              let voiceChannel = conversation.voiceChannel else {
            return
        }

        visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel, selfUser: ZMUser.selfUser())
        visibleVoiceChannelViewController.delegate = self
    }

    func transition(to toViewController: UIViewController, from fromViewController: UIViewController) {
        guard toViewController != fromViewController else { return }

        zmLog.debug(String(format: "Transitioning to CallViewController: %p from: %p", toViewController, fromViewController))

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

    var ongoingCallConversation: ZMConversation? {
        return ZMUserSession.shared()?.ongoingCallConversation
    }

}

extension ActiveCallViewController: WireCallCenterCallStateObserver {

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateVisibleVoiceChannelViewController()
    }

}

extension ActiveCallViewController: CallViewControllerDelegate {
    func callViewControllerDidDisappear(_ callController: CallViewController,
                                        for conversation: ZMConversation?) {
        delegate?.activeCallViewControllerDidDisappear(self, for: conversation)
    }
}
