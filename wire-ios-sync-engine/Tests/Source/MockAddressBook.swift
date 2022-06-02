//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireSyncEngine

/// Fake to supply predefined AB hashes
class MockAddressBook: WireSyncEngine.AddressBook, WireSyncEngine.AddressBookAccessor {

    /// Find contact by Id
    func contact(identifier: String) -> WireSyncEngine.ContactRecord? {
        return contacts.first { $0.localIdentifier == identifier }
    }

    /// List of contacts in this address book
    var contacts = [MockAddressBookContact]()

    /// Reported number of contacts (it might be higher than `fakeContacts`
    /// because some contacts are filtered for not having valid email/phone)
    var numberOfAdditionalContacts: UInt = 0

    var numberOfContacts: UInt {
        return UInt(self.contacts.count) + numberOfAdditionalContacts
    }

    /// Enumerates the contacts, invoking the block for each contact.
    /// If the block returns false, it will stop enumerating them.
    func enumerateRawContacts(block: @escaping (WireSyncEngine.ContactRecord) -> (Bool)) {
        for contact in self.contacts {
            if !block(contact) {
                return
            }
        }
        let infiniteContact = MockAddressBookContact(firstName: "johnny infinite",
                                                     emailAddresses: ["johnny.infinite@example.com"],
                                                     phoneNumbers: [])
        while createInfiniteContacts {
            if !block(infiniteContact) {
                return
            }
        }
    }

    func rawContacts(matchingQuery: String) -> [WireSyncEngine.ContactRecord] {
        guard matchingQuery != "" else {
            return contacts
        }
        return contacts.filter { $0.firstName.lowercased().contains(matchingQuery.lowercased()) || $0.lastName.lowercased().contains(matchingQuery.lowercased()) }
    }

    /// Replace the content with a given number of random hashes
    func fillWithContacts(_ number: UInt) {
        self.contacts = (0..<number).map {
            self.createContact(card: $0)
        }
    }

    /// Create a fake contact
    func createContact(card: UInt) -> MockAddressBookContact {
        return MockAddressBookContact(firstName: "tester \(card)", emailAddresses: ["tester_\(card)@example.com"], phoneNumbers: ["+155512300\(card % 10)"], identifier: "\(card)")
    }

    /// Generate an infinite number of contacts
    var createInfiniteContacts = false
}

struct MockAddressBookContact: WireSyncEngine.ContactRecord {

    static var incrementalLocalIdentifier = ZMAtomicInteger(integer: 0)

    var firstName = ""
    var lastName = ""
    var middleName = ""
    var rawEmails: [String]
    var rawPhoneNumbers: [String]
    var nickname = ""
    var organization = ""
    var localIdentifier = ""

    init(firstName: String, emailAddresses: [String], phoneNumbers: [String], identifier: String? = nil) {
        self.firstName = firstName
        self.rawEmails = emailAddresses
        self.rawPhoneNumbers = phoneNumbers
        self.localIdentifier = identifier ?? {
            MockAddressBookContact.incrementalLocalIdentifier.increment()
            return "\(MockAddressBookContact.incrementalLocalIdentifier.rawValue)"
            }()
    }

    var expectedHashes: [String] {
        return self.rawEmails.map { $0.base64EncodedSHADigest } + self.rawPhoneNumbers.map { $0.base64EncodedSHADigest }
    }
}
