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
import WireDataModel
import avs
import WireSyncEngine

private let zmLog = ZMSLog(tag: "calling")

final class ProximityMonitorManager: NSObject {

    typealias RaisedToEarHandler = (_ raisedToEar: Bool) -> Void

    var callStateObserverToken: Any?

    fileprivate(set) var raisedToEar: Bool = false {
        didSet {
            if oldValue != self.raisedToEar {
                self.stateChanged?(self.raisedToEar)
            }
        }
    }

    var stateChanged: RaisedToEarHandler?
    var listening: Bool = false

    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
        self.stopListening()
        NotificationCenter.default.removeObserver(self)
    }

    override init() {
        super.init()

        guard let userSession = ZMUserSession.shared() else {
            zmLog.error("UserSession not available when initializing \(type(of: self))")
            return
        }

        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        AVSMediaManagerClientChangeNotification.add(self)

        updateProximityMonitorState()
    }

    func updateProximityMonitorState() {
        // Only do proximity monitoring on phones
        guard UIDevice.current.userInterfaceIdiom == .phone, let callCenter = ZMUserSession.shared()?.callCenter, !listening else { return }

        let ongoingCalls = callCenter.nonIdleCalls.filter({ (_, callState: CallState) -> Bool in
            switch callState {
            case .established, .establishedDataChannel, .answered(degraded: false), .outgoing(degraded: false):
                return true
            default:
                return false
            }
        })

        let hasOngoingCall = ongoingCalls.count > 0
        let speakerIsEnabled = AVSMediaManager.sharedInstance()?.isSpeakerEnabled ?? false

        UIDevice.current.isProximityMonitoringEnabled = !speakerIsEnabled && hasOngoingCall
    }

    // MARK: - listening mode switching (for AudioMessageView)

    func startListening() {
        guard !self.listening else {
            return
        }

        self.listening = true

        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleProximityChange),
                                               name: UIDevice.proximityStateDidChangeNotification,
                                               object: nil)
    }

    func stopListening() {
        guard self.listening else {
            return
        }
        self.listening = false

        UIDevice.current.isProximityMonitoringEnabled = false
    }

    @objc func handleProximityChange(_ notification: Notification) {
        self.raisedToEar = UIDevice.current.proximityState
    }

}

extension ProximityMonitorManager: WireCallCenterCallStateObserver {

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateProximityMonitorState()
    }

}

extension ProximityMonitorManager: AVSMediaManagerClientObserver {

    func mediaManagerDidChange(_ notification: AVSMediaManagerClientChangeNotification!) {
        if notification.speakerEnableChanged {
            updateProximityMonitorState()
        }
    }

}
