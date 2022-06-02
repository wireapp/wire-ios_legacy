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

private enum PushChannelKeys: String {
    case data = "data"
    case identifier = "id"
    case notificationType = "type"
}

private enum PushNotificationType: String {
    case plain
    case cipher
    case notice
}

@objc
public extension ZMOperationLoop {

    @objc(fetchEventsFromPushChannelPayload:completionHandler:)
    func fetchEvents(fromPushChannelPayload payload: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        guard let nonce = messageNonce(fromPushChannelData: payload) else {
            return completionHandler()
        }

        pushNotificationStatus.fetch(eventId: nonce, completionHandler: {
            self.callEventStatus.waitForCallEventProcessingToComplete { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.syncMOC.performGroupedBlock {
                    completionHandler()
                }
            }
        })
    }

    func messageNonce(fromPushChannelData payload: [AnyHashable: Any]) -> UUID? {
        guard let notificationData = payload[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
              let rawNotificationType = notificationData[PushChannelKeys.notificationType.rawValue] as? String,
              let notificationType = PushNotificationType(rawValue: rawNotificationType) else {
            return nil
        }

        switch notificationType {
        case .plain, .notice:
            if let data = notificationData[PushChannelKeys.data.rawValue] as? [AnyHashable: Any], let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String {
                return UUID(uuidString: rawUUID)
            }
        case .cipher:
            return messageNonce(fromEncryptedPushChannelData: notificationData)
        }

        return nil
    }

    func messageNonce(fromEncryptedPushChannelData encryptedPayload: [AnyHashable: Any]) -> UUID? {
        //    @"aps" : @{ @"alert": @{@"loc-args": @[],
        //                          @"loc-key"   : @"push.notification.new_message"}
        //              },
        //    @"data": @{ @"data" : @"SomeEncryptedBase64EncodedString",
        //                @"mac"  : @"someMacHashToVerifyTheIntegrityOfTheEncodedPayload",
        //                @"type" : @"cipher"
        //

        guard let apsSignalKeyStore = apsSignalKeyStore else {
            Logging.network.debug("Could not initiate APSSignalingKeystore")
            return nil
        }

        guard let decryptedPayload = apsSignalKeyStore.decryptDataDictionary(encryptedPayload) else {
            Logging.network.debug("Failed to decrypt data dictionary from push payload: \(encryptedPayload)")
            return nil
        }

        if let data = decryptedPayload[PushChannelKeys.data.rawValue] as? [AnyHashable: Any], let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String {
            return UUID(uuidString: rawUUID)
        }

        return nil
    }

}
