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

private let zmLog = ZMSLog(tag: "ContactAddressBook")

/// iOS Contacts-based address book
final class ContactAddressBook: AddressBook {

    let store = CNContactStore()
}

extension ContactAddressBook: AddressBookAccessor {

    /// Gets a specific address book user by the local address book indentifier
    internal func contact(identifier: String) -> ContactRecord? {
        return try? store.unifiedContact(withIdentifier: identifier, keysToFetch: ContactAddressBook.keysToFetch)
    }

    static var keysToFetch: [CNKeyDescriptor] {
        return  [CNContactPhoneNumbersKey as CNKeyDescriptor,
                 CNContactEmailAddressesKey as CNKeyDescriptor,
                 CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                 CNContactOrganizationNameKey as CNKeyDescriptor]
    }

    func rawContacts(matchingQuery query: String) -> [ContactRecord] {
        guard AddressBook.accessGranted() else {
            return []
        }

        guard !query.isEmpty else {
            return self.firstRawContacts(number: addressBookContactsSearchLimit)
        }

        let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: query.lowercased())
        guard let foundContacts = try? CNContactStore().unifiedContacts(matching: predicate, keysToFetch: ContactAddressBook.keysToFetch) else {
            return []
        }
        return foundContacts
    }

    /// Enumerates the contacts, invoking the block for each contact.
    /// If the block returns false, it will stop enumerating them.
    func enumerateRawContacts(block: @escaping (ContactRecord) -> (Bool)) {
        let request = CNContactFetchRequest(keysToFetch: ContactAddressBook.keysToFetch)
        request.sortOrder = .userDefault
        do {
            try store.enumerateContacts(with: request) { (contact, stop) in
                let shouldContinue = block(contact)
                stop.initialize(to: ObjCBool(!shouldContinue))
            }
        } catch {
            zmLog.error(error.localizedDescription)
        }
    }

    /// Number of contacts in the address book
    var numberOfContacts: UInt {
        return 0
    }
}

extension CNContact: ContactRecord {

    var rawEmails: [String] {
        return self.emailAddresses.map { $0.value as String }
    }

    var rawPhoneNumbers: [String] {
        return self.phoneNumbers.map { $0.value.stringValue }
    }

    var firstName: String {
        return self.givenName
    }

    var lastName: String {
        return self.familyName
    }

    var organization: String {
        return self.organizationName
    }

    var localIdentifier: String {
        return self.identifier
    }
}

extension ZMAddressBookContact {

    convenience init?(contact: CNContact,
                      phoneNumberNormalizer: @escaping AddressBook.Normalizer,
                      emailNormalizer: @escaping AddressBook.Normalizer) {
        self.init()

        // names
        self.firstName = contact.givenName
        self.lastName = contact.familyName
        self.middleName = contact.middleName
        self.nickname = contact.nickname
        self.organization = contact.organizationName

        // email
        self.emailAddresses = contact.emailAddresses.compactMap { emailNormalizer($0.value as String) }

        // phone
        self.rawPhoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }

        // normalize phone
        self.phoneNumbers = self.rawPhoneNumbers.compactMap { phoneNumberNormalizer($0) }

        // ignore contacts with no email nor phones
        guard self.emailAddresses.count > 0 || self.phoneNumbers.count > 0 else {
            return nil
        }
    }
}
