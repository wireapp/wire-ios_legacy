//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension Account {
    func userDefaultsKey() -> String {
        return "account_\(self.userIdentifier.transportString())"
    }
}

extension Settings {
    private func payload(for account: Account) -> [String: Any] {
        return defaults.value(forKey: account.userDefaultsKey()) as? [String: Any] ?? [:]
    }

    /// Returns the value associated with the given account for the given key
    ///
    /// - Parameters:
    ///   - key: the SettingKey enum
    ///   - account: account to get value
    /// - Returns: the setting of the account
    func value<T>(for settingKey: SettingKey, in account: Account) -> T? {
        let key = settingKey.rawValue

        // Attempt to migrate the shared value
        if let rootValue = defaults.value(forKey: key) {
            setValue(rootValue, settingKey: settingKey, in: account)
            defaults.removeObject(forKey: key)
            defaults.synchronize()
        }

        let accountPayload = payload(for: account)
        return accountPayload[key] as? T
    }

    /// Sets the value associated with the given account for the given key.
    ///
    /// - Parameters:
    ///   - value: value to set
    ///   - settingKey: the SettingKey enum
    ///   - account: account to set value
    func setValue<T>(_ value: T?, settingKey: SettingKey, in account: Account) {
        let key = settingKey.rawValue
        var accountPayload = self.payload(for: account)
        accountPayload[key] = value
        defaults.setValue(accountPayload, forKey: account.userDefaultsKey())
    }

    func lastViewedConversation(for account: Account) -> ZMConversation? {
        guard let conversationID: String = self.value(for: .lastViewedConversation, in: account) else {
            return nil
        }

        let conversationURI = URL(string: conversationID)
        let session = ZMUserSession.shared()
        let objectID = ZMManagedObject.objectID(forURIRepresentation: conversationURI, inUserSession: session)
        return ZMConversation.existingObject(with: objectID, inUserSession: session)
    }

    func setLastViewed(conversation: ZMConversation, for account: Account) {
        let conversationURI = conversation.objectID.uriRepresentation()
        setValue(conversationURI.absoluteString, settingKey: .lastViewedConversation, in: account)
        defaults.synchronize()
    }

    func notifyDisableSendButtonChanged() {
        NotificationCenter.default.post(name: .disableSendButtonChanged, object: self, userInfo: nil)
    }
}

extension Notification.Name {
    static let disableSendButtonChanged = Notification.Name("DisableSendButtonChanged")
}
