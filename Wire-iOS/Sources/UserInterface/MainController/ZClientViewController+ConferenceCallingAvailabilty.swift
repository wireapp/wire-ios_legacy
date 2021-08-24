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

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(.ok())

        let configuration = AlertConfiguration(message: message, subMessage: learnMore, link: URL.wr_wireEnterpriseLearnMore)
        alert.setValue(createMessageView(configuration), forKey: "contentViewController")
        present(alert, animated: true)
    }

    func presentConferenceCallingUnavailableAlertForAdmin() {
        typealias ConferenceCallingRestrictions = L10n.Localizable.FeatureConfig.ConferenceCallingRestrictions.Admins
        typealias ConferenceCallingAlert = ConferenceCallingRestrictions.Alert
        let title = ConferenceCallingAlert.title
        let message = ConferenceCallingAlert.message
        let learnMore = ConferenceCallingAlert.Message.learnMore
        let upgradeButtonTitle = ConferenceCallingRestrictions.UpgradeButton.title

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(.cancel())

        alert.addAction(.init(title: upgradeButtonTitle, style: .default, handler: { (_) in
            let browserViewController = BrowserViewController(url: URL.manageTeam(source: .settings))
            self.present(browserViewController, animated: true)
        }))
        let configuration = AlertConfiguration(message: message, subMessage: learnMore, link: URL.wr_wirePricingLearnMore)
        alert.setValue(createMessageView(configuration), forKey: "contentViewController")
        present(alert, animated: true)
    }

    func presentConferenceCallingUnavailableAlertForMember() {
        typealias ConferenceCallingAlert = L10n.Localizable.FeatureConfig.ConferenceCallingRestrictions.Members.Alert
        let title = ConferenceCallingAlert.title
        let message = ConferenceCallingAlert.message

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.ok())

        present(alert, animated: true)
    }


    private struct AlertConfiguration {
        let message: String
        let subMessage: String
        let link: URL
    }

    private func createMessageView(_ configuration: AlertConfiguration) -> UIViewController {
        let controller = UIViewController()
        let textView = UITextView()
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.frame = controller.view.frame
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        textView.backgroundColor = .clear

        let font = UIFont.mediumFont
        let color = UIColor.from(scheme: .textForeground)

        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.accent(),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: UIColor.clear,
            .font: font,
            .link: configuration.link
        ]

        let message = (configuration.message && font && color && .lineSpacing(4)) + "\n" + (configuration.subMessage && linkAttributes)
        textView.attributedText = message
        textView.linkTextAttributes = [:]
        textView.isEditable = false
        textView.isUserInteractionEnabled = true

        controller.view.addSubview(textView)

        return controller
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

            /// TODO katerina  ask what should we display in this case
        case .conferenceCallingIsUnavailable:
            presentConferenceCallingAvailableAlert()
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
        guard let selfUser = ZMUser.selfUser(),
              selfUser.teamRole.isOne(of: .admin, .owner) else {
            presentConferenceCallingUnavailableAlertForMember()
            return
        }
        presentConferenceCallingUnavailableAlertForAdmin()
    }

}
