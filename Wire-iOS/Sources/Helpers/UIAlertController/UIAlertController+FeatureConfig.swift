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

protocol FeatureChangeAcknowledger {

    func acknowledgeChange(for featureName: Feature.Name)

}

extension FeatureService: FeatureChangeAcknowledger {

    func acknowledgeChange(for featureName: Feature.Name) {
        setNeedsToNotifyUser(false, for: featureName)
    }

}

extension UIAlertController {

    class func fromFeatureChange(_ change: FeatureService.FeatureChange,
                                 acknowledger: FeatureChangeAcknowledger) -> UIAlertController? {
        switch change {
        case .conferenceCallingIsAvailable:
            // Handled elsewhere.
            return nil

        case .selfDeletingMessagesIsDisabled:
            return alertForFeatureChange(message: Strings.Alert.SelfDeletingMessages.Message.disabled,
                                         onOK: { acknowledger.acknowledgeChange(for: .selfDeletingMessages) })

        case .selfDeletingMessagesIsEnabled(enforcedTimeout: nil):
            return alertForFeatureChange(message: Strings.Alert.SelfDeletingMessages.Message.enabled,
                                         onOK: { acknowledger.acknowledgeChange(for: .selfDeletingMessages) })

        case .selfDeletingMessagesIsEnabled(let enforcedTimeout?):
            let timeout = MessageDestructionTimeoutValue(rawValue: TimeInterval(enforcedTimeout))
            guard let timeoutString = timeout.displayString else { return nil }

            return alertForFeatureChange(message: Strings.Alert.SelfDeletingMessages.Message.forcedOn(timeoutString),
                                         onOK: { acknowledger.acknowledgeChange(for: .selfDeletingMessages) })

        case .fileSharingEnabled:
            return alertForFeatureChange(message: Strings.Update.FileSharing.Alert.Message.enabled,
                                         onOK: { acknowledger.acknowledgeChange(for: .fileSharing) })

        case .fileSharingDisabled:
            return alertForFeatureChange(message: Strings.Update.FileSharing.Alert.Message.disabled,
                                         onOK: { acknowledger.acknowledgeChange(for: .fileSharing) })

        case .conversationGuestLinksEnabled:
            return alertForFeatureChange(message: Strings.Alert.ConversationGuestLinks.Message.enabled,
                                         onOK: { acknowledger.acknowledgeChange(for: .conversationGuestLinks) })

        case .conversationGuestLinksDisabled:
            return alertForFeatureChange(message: Strings.Alert.ConversationGuestLinks.Message.disabled,
                                         onOK: { acknowledger.acknowledgeChange(for: .conversationGuestLinks) })

        }
    }

}

private extension UIAlertController {

    // MARK: - Helpers

    typealias Strings = L10n.Localizable.FeatureConfig

    static func alertForFeatureChange(message: String,
                                      onOK: @escaping () -> Void) -> UIAlertController {

        return UIAlertController(title: Strings.Alert.genericTitle,
                                 message: message,
                                 alertAction: .ok { _ in onOK() })
    }

}
