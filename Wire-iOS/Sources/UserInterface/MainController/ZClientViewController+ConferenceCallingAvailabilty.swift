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
        typealias ConferenceCallingAlert = L10n.Localizable.FeatureConfig.Update.ConferenceCalling.Alert
        let title = ConferenceCallingAlert.title
        let message = ConferenceCallingAlert.message
        let learnMore = ConferenceCallingAlert.Message.learnMore

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: learnMore, style: .default, handler: { (_) in
            let browserViewController = BrowserViewController(url: URL.wr_wireEnterpriseLearnMore)
            self.present(browserViewController, animated: true)
        }))
        alert.addAction(UIAlertAction.ok(style: .default, handler: { [weak self] (_) in
            self?.confirmChanges()
        }))

        present(alert, animated: true)
    }

    func presentConferenceCallingRestrictionAlertForAdmin() {
        typealias ConferenceCallingRestrictions = L10n.Localizable.FeatureConfig.ConferenceCallingRestrictions.Admins
        typealias ConferenceCallingAlert = ConferenceCallingRestrictions.Alert
        let title = ConferenceCallingAlert.title
        let message = ConferenceCallingAlert.message
        let learnMore = ConferenceCallingAlert.Message.learnMore
        let upgradeButtonTitle = ConferenceCallingRestrictions.UpgradeButton.title

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: learnMore, style: .default, handler: { (_) in
            let browserViewController = BrowserViewController(url: URL.wr_wirePricingLearnMore)
            self.present(browserViewController, animated: true)
        }))
        alert.addAction(.cancel())
        alert.addAction(.init(title: upgradeButtonTitle, style: .default, handler: { (_) in
            let browserViewController = BrowserViewController(url: URL.manageTeam(source: .settings))
            self.present(browserViewController, animated: true)
        }))

        present(alert, animated: true)
    }

    func presentConferenceCallingRestrictionAlertForMember() {
        typealias ConferenceCallingAlert = L10n.Localizable.FeatureConfig.ConferenceCallingRestrictions.Members.Alert
        let title = ConferenceCallingAlert.title
        let message = ConferenceCallingAlert.message

        let alert = UIAlertController.alertWithOKButton(title: title, message: message)
        present(alert, animated: true)
    }

    private func confirmChanges() {
        guard let session = ZMUserSession.shared() else { return }
        session.featureService.setNeedsToNotifyUser(false, for: .conferenceCalling)
    }

}

extension ZClientViewController: ConferenceCallingUnavailableObserver {

    func setUpConferenceCallingUnavailableObserver() {
        guard let session = ZMUserSession.shared() else { return }
        let token = WireCallCenterV3.addConferenceCallingUnavailableObserver(observer: self, userSession: session)
        conferenceCallingUnavailableObserverToken = token
    }

    func callCenterDidNotStartConferenceCall() {
        guard let selfUser = ZMUser.selfUser() else { return }

        if selfUser.teamRole.isOne(of: .admin, .owner) {
            presentConferenceCallingRestrictionAlertForAdmin()
        } else {
            presentConferenceCallingRestrictionAlertForMember()
        }
    }

}
