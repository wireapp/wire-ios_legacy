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
import Contacts
import WireSyncEngine
import UIKit

protocol AddressBookHelperProtocol: class {
    var isAddressBookAccessGranted: Bool { get }
    var isAddressBookAccessUnknown: Bool { get }
    var isAddressBookAccessDisabled: Bool { get }
    var accessStatusDidChangeToGranted: Bool { get }

    static var sharedHelper: AddressBookHelperProtocol { get }

    func requestPermissions(_ callback: ((Bool)->())?)
    func persistCurrentAccessStatus()
}

/// Allows access to address book for search
final class AddressBookHelper: AddressBookHelperProtocol {

    /// Singleton
    static var sharedHelper: AddressBookHelperProtocol = AddressBookHelper()

    // MARK: - Constants

    private let addressBookLastAccessStatusKey = "AddressBookLastAccessStatus"

    // MARK: - Permissions

    var isAddressBookAccessUnknown: Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .notDetermined
    }

    var isAddressBookAccessGranted: Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    var isAddressBookAccessDisabled: Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .denied
    }

    /// Request access to the user. Will asynchronously invoke the callback passing as argument
    /// whether access was granted.
    func requestPermissions(_ callback: ((Bool)->())?) {
        CNContactStore().requestAccess(for: .contacts, completionHandler: { [weak self] authorized, _ in
            DispatchQueue.main.async {
                self?.persistCurrentAccessStatus()
                callback?(authorized)
            }
        })
    }

    // MARK: – Access Status Change Detection

    func persistCurrentAccessStatus() {
        let status = CNContactStore.authorizationStatus(for: .contacts).rawValue as Int
        UserDefaults.standard.set(NSNumber(value: status), forKey: addressBookLastAccessStatusKey)
    }

    private var lastAccessStatus: CNAuthorizationStatus? {
        guard let value = UserDefaults.standard.object(forKey: addressBookLastAccessStatusKey) as? NSNumber else { return nil }
        return CNAuthorizationStatus(rawValue: value.intValue)
    }

    var accessStatusDidChangeToGranted: Bool {
        guard let lastStatus = lastAccessStatus else { return false }
        return CNContactStore.authorizationStatus(for: .contacts) != lastStatus && isAddressBookAccessGranted
    }

}
