//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireSyncEngine

extension ZClientViewController {

    // We need an alert that conference calling changed.
    // Feature service could do this.
    // So let's introduce Feature config change notificaitons, observed by the
    // Feature Service, which will then post other notifications.

    func presentConferenceCallingAvailableAlert() {
        let title = "Wire enterprise"
        let message = "Your team is was upgraded to Wire enterprise, which gives you access to features such as conference calls and more."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.ok())

        present(alert, animated: true)
    }

    func presentConferenceCallingUnavailableAlert() {
        let title = "Upgrade to enterprise"
        let message = "Your team is currently on the free basic plan. Upgrade to Enterprise for access to features such as starting conferences and more."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.cancel())
        alert.addAction(.init(title: "Upgrade now", style: .default, handler: nil))

        present(alert, animated: true)
    }

}

extension ZClientViewController: FeatureServiceDelegate {

    func setUpFeatureChangeObservation() {
        guard let featureService = ZMUserSession.shared()?.featureService else { return }
        featureService.delegate = self
    }

    func featureService(_ service: FeatureService, didDetectChange change: FeatureService.FeatureChange) {
        switch change {
        case .conferenceCallingIsAvailable:
            presentConferenceCallingAvailableAlert()

        case .conferenceCallingIsUnavailable:
            presentConferenceCallingUnavailableAlert()
        }
    }

}

extension ZClientViewController: ConferenceCallingUnavailableObserver {

    func setUpConferenceCallingUnavailableObserver() {
        guard let session = ZMUserSession.shared() else { return }
        let token = WireCallCenterV3.addConferenceCallingUnavailableObserver(observer: self, userSession: session)
        conferenceCallingUnavailableObserverToken = token
    }

    func callCenterDidNotStartConferenceCall() {
        presentConferenceCallingUnavailableAlert()
    }

}
