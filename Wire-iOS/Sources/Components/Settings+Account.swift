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

extension Account {
    func userDefaultsKey() -> String {
        return "account_\(self.userIdentifier.transportString())"
    }
}

extension Settings {
    private func payload(for account: Account) -> [String: Any] {
        return self.defaults().value(forKey: account.userDefaultsKey()) as? [String: Any] ?? [:]
    }
    
    /// Returns the value associated with the given account for the given key,
    /// or nil if it doesn't exist.
    ///
    func value<T>(for key: String, in account: Account) -> T? {
        // Attempt to migrate the shared value
        if let rootValue = self.defaults().value(forKey: key) {
            setValue(rootValue, for: key, in: account)
            self.defaults().setValue(nil, forKey: key)
            self.defaults().synchronize()
        }
        
        var accountPayload = self.payload(for: account)
        return accountPayload[key] as? T
    }
    
    /// Sets the value associated with the given account for the given key.
    ///
    func setValue<T>(_ value: T?, for key: String, in account: Account) {
        var accountPayload = self.payload(for: account)
        accountPayload[key] = value
        self.defaults().setValue(accountPayload, forKey: account.userDefaultsKey())
    }
    
    @objc func lastViewedConversation(for account: Account) -> ZMConversation? {
        guard let conversationID: String = self.value(for: UserDefaultLastViewedConversation, in: account) else {
            return nil
        }
        
        let conversationURI = URL(string: conversationID)
        let session = ZMUserSession.shared()
        let objectID = ZMManagedObject.objectID(forURIRepresentation: conversationURI, inUserSession: session)
        return ZMConversation.existingObject(with: objectID, inUserSession: session)
    }

    @objc func setLastViewed(conversation: ZMConversation, for account: Account) {
        let conversationURI = conversation.objectID.uriRepresentation()
        self.setValue(conversationURI.absoluteString, for: UserDefaultLastViewedConversation, in: account)
        self.defaults().synchronize()
    }
}
