//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ConversationViewController {

    private enum PrivacyAlertAction {
        case verifyDevices
        case sendAnyway
        case legalHoldDetails
        case cancel

        var localizedTitle: String {
            typealias Meta = L10n.Localizable.Meta
            switch self {
            case .verifyDevices:
                return Meta.Degraded.verifyDevicesButton
            case .sendAnyway:
                return Meta.Degraded.sendAnywayButton
            case .legalHoldDetails:
                return Meta.Legalhold.infoButton
            case .cancel:
                return L10n.Localizable.General.cancel
            }
        }

        var preferredStyle: UIAlertAction.Style {
            switch self {
            case .cancel:
                return .cancel
            default:
                return .default
            }
        }
    }

    // MARK: - Alert

    /// Presents an alert in response to a change in privacy (legal hold and/or client verification).
    func presentPrivacyWarningAlert(for changeInfo: ConversationChangeInfo) {
        let title: String
        let message = L10n.Localizable.Meta.Degraded.dialogMessage
        var actions: [PrivacyAlertAction] = []

        if conversation.legalHoldStatus == .pendingApproval {
            title = L10n.Localizable.Meta.Legalhold.sendAlertTitle
            actions.append(.legalHoldDetails)

            if conversation.securityLevel == .secureWithIgnored {
                actions.append(.verifyDevices)
            }

            actions += [.sendAnyway, .cancel]
        } else if conversation.securityLevel == .secureWithIgnored {
            let users = changeInfo.usersThatCausedConversationToDegrade
            let names = changeInfo.usersThatCausedConversationToDegrade.compactMap(\.name).joined(separator: ", ")
            title = users.count <= 1
                ? L10n.Localizable.Meta.Degraded.DegradationReasonMessage.singular(names)
                : L10n.Localizable.Meta.Degraded.DegradationReasonMessage.plural(names)

            actions += [.verifyDevices, .sendAnyway, .cancel]
        } else {
            // no-op: there is no privacy warning
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for action in actions {
            let alertAction = UIAlertAction(title: action.localizedTitle, style: action.preferredStyle) { [weak self] _ in
                self?.performPrivacyAction(action)
            }

            alert.addAction(alertAction)
        }

        present(alert, animated: true)
    }

    // MARK: - Handling the Result

    private func performPrivacyAction(_ action: PrivacyAlertAction) {
        switch action {
        case .verifyDevices:
            conversation.acknowledgePrivacyWarning(withResendIntent: false)
            presentVerificationScreen()
        case .legalHoldDetails:
            conversation.acknowledgePrivacyWarning(withResendIntent: false)
            presentLegalHoldDetails()
        case .sendAnyway:
            conversation.acknowledgePrivacyWarning(withResendIntent: true)
        case .cancel:
            conversation.acknowledgePrivacyWarning(withResendIntent: false)
        }
    }

    private func presentVerificationScreen() {
        guard let selfUser = ZMUser.selfUser() else { return }

        if selfUser.hasUntrustedClients {
            ZClientViewController.shared?.openClientListScreen(for: selfUser)
        } else if let connectedUser = conversation.connectedUser, conversation.conversationType == .oneOnOne {
            let profileViewController = ProfileViewController(user: connectedUser, viewer: selfUser, conversation: conversation, context: .deviceList)
            profileViewController.delegate = self
            profileViewController.viewControllerDismisser = self
            let navigationController = profileViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        } else if conversation.conversationType == .group {
            let participantsViewController = GroupParticipantsDetailViewController(selectedParticipants: [], conversation: conversation)
            let navigationController = participantsViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        }
    }

    private func presentLegalHoldDetails() {
        LegalHoldDetailsViewController.present(in: self, conversation: conversation)
    }

}
