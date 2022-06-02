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
import libPhoneNumberiOS

/// Wraps the system address book to return `ZMAddressBookContact` when iterating, filtering out those
/// without a valid email or phone
protocol AddressBookAccessor {

    /// Number of contacts in the address book
    var numberOfContacts: UInt {get}

    /// Enumerates the contacts whitout performing any normalization or validation, invoking the block for each contact.
    /// If the block returns false, it will stop enumerating them.
    func enumerateRawContacts(block: @escaping (ContactRecord) -> (Bool))

    /// Returns contacts matching search query
    func rawContacts(matchingQuery: String) -> [ContactRecord]

    /// Normalization function for phone numbers
    var phoneNumberNormalizer: AddressBook.Normalizer { get }

    /// Gets a specific address book user by the local address book indentifier
    func contact(identifier: String) -> ContactRecord?
}

extension AddressBookAccessor {

    /// Enumerates the contacts, normalized and validated, invoking the block for each contact.
    /// Non valid contacts (no email nor phone) will be excluded from the enumeration.
    /// If the block returns false, it will stop enumerating them.
    func enumerateValidContacts(block: @escaping (ZMAddressBookContact) -> (Bool)) {
        self.enumerateRawContacts {
            guard let parsed = ZMAddressBookContact(contact: $0, phoneNumberNormalizer: self.phoneNumberNormalizer) else {
                return true
            }
            return block(parsed)
        }
    }

    /// Returns valid contacts matching the search query, with normalized email and phone numbers
    func contacts(matchingQuery: String) -> [ZMAddressBookContact] {
        return self.rawContacts(matchingQuery: matchingQuery)
            .compactMap { ZMAddressBookContact(contact: $0, phoneNumberNormalizer: self.phoneNumberNormalizer) }
    }

    /// Encodes an arbitraty part the address book asynchronously. Will invoke the completion handler when done.
    /// - parameter groupQueue: group queue to enter while executing, and where to invoke callback
    /// - parameter completion: closure invoked when the address book encoding ended. It will receive nil parameter
    ///     if there are no contacts to upload
    /// - parameter maxNumberOfContacts: do not include more than this number of contacts
    /// - parameter startingContactIndex: include contacts starting from this index in the address book
    func encodeWithCompletionHandler(_ groupQueue: ZMSGroupQueue,
                                     startingContactIndex: UInt,
                                     maxNumberOfContacts: UInt,
                                     completion: @escaping (EncodedAddressBookChunk?) -> Void
        ) {
        // here we are explicitly capturing self, this is executed on a queue that is
        // never blocked indefinitely as this is the only function using it
        groupQueue.dispatchGroup.async(on: addressBookProcessingQueue) {

            let range: Range<UInt> = startingContactIndex..<(startingContactIndex+maxNumberOfContacts)
            let cards = self.generateContactCards(range: range)

            guard cards.count > 0 || startingContactIndex > 0 else {
                // this should happen if I have zero contacts
                groupQueue.performGroupedBlock({
                    completion(nil)
                })
                return
            }

            let cardsRange = startingContactIndex..<(startingContactIndex+UInt(cards.count))
            let encodedAB = EncodedAddressBookChunk(numberOfTotalContacts: self.numberOfContacts,
                                                    otherContactsHashes: cards,
                                                    includedContacts: cardsRange)
            groupQueue.performGroupedBlock({
                completion(encodedAB)
            })
        }
    }

    /// Generate contact cards for the given range of contacts
    fileprivate func generateContactCards(range: Range<UInt>) -> [String: [String]] {
        var cards = [String: [String]]()

        self.contacts(range: range).enumerated().forEach {
            let contact = $0.element
            cards[contact.localIdentifier ?? "\($0.offset)"] = (contact.emailAddresses.map { $0.base64EncodedSHADigest })
                + (contact.phoneNumbers.map { $0.base64EncodedSHADigest })
        }
        return cards
    }

    /// Returns contacts in a specific range
    func contacts(range: Range<UInt>) -> [ZMAddressBookContact] {
        var contacts = [ZMAddressBookContact]()

        let maxElements = Int(range.upperBound - range.lowerBound)
        contacts.reserveCapacity(maxElements)

        var skipped: UInt = 0
        self.enumerateValidContacts { (contact) -> (Bool) in
            if skipped < range.lowerBound {
                skipped += 1
                return true
            }
            contacts.append(contact)
            return contacts.count < maxElements
        }

        return contacts
    }

    /// Returns the first X raw contacts from the address book
    func firstRawContacts(number: Int) -> [ContactRecord] {
        var contacts = [ContactRecord]()
        contacts.reserveCapacity(number)
        var count = 0
        self.enumerateRawContacts { record in
            contacts.append(record)
            count += 1
            return count < number
        }
        return contacts
    }
}

/// Common base class between iOS 8 (AddressBook framework) and iOS 9+ (Contacts framework)
class AddressBook {

    /// normalizer for phone numbers
    let phoneNumberNormalizer: AddressBook.Normalizer

    init() {
        let libPhoneNumber = NBPhoneNumberUtil()
        self.phoneNumberNormalizer = { libPhoneNumber.normalize(phoneNumber: $0)?.validatedPhoneNumber }
    }

    typealias Normalizer = (String) -> (String?)
    typealias AccessCheck = () -> (Bool)

    /// Will return an instance of the address book accessor best suited for the
    /// current OS version. Will return `nil` if the user did not grant access to the AB
    static func factory() -> AddressBookAccessor? {
        guard self.accessGranted() else {
            return nil
        }

        return ContactAddressBook()
    }

    /// Uses the passed in closure, or the standard method if the closure is nil, to
    /// check if the AB access was granted. Returns whether it was granted.
    static func accessGranted(_ checkClosure: AccessCheck? = nil) -> Bool {
        if let closure = checkClosure {
            return closure()
        }
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
}

// MARK: - Encoded address book chunk
struct EncodedAddressBookChunk {

    /// Total number of contacts in the address book
    let numberOfTotalContacts: UInt

    /// Data to upload for contacts other that the self user
    /// maps from contact ID to hashes
    let otherContactsHashes: [String: [String]]

    /// Contacts included in this chunck, according to AB order
    let includedContacts: CountableRange<UInt>
}

// MARK: - Phone number and email normalization
extension NBPhoneNumberUtil {

    /// Returns a normalized version of the phone number, or nil
    /// if the phone number was not normalizable.
    /// - note: numbers starting with "+0", a prefix that is not
    /// assigned to any real number, are considered test numbers
    /// used for QA automation and will always be accepted, without being
    /// normalized through the normalization library but just sanitized
    /// from any non-numberic character
    fileprivate func normalize(phoneNumber: String) -> String? {
        let testingNumberPrefix = "+0"
        guard !phoneNumber.hasPrefix(testingNumberPrefix) else {
            return phoneNumber.validatedPhoneNumber
        }

        guard let parsedNumber = try? self.parse(withPhoneCarrierRegion: phoneNumber) else {
            return nil
        }
        guard let normalizedNumber = try? self.format(parsedNumber, numberFormat: .E164) else {
            return nil
        }
        return normalizedNumber
    }

}

extension String {

    /// Returns a normalized phone number or nil
    var validatedPhoneNumber: String? {

        // allow +0 numbers
        if self.hasPrefix("+0") {
            return "+" + (self
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined(separator: "")) // remove all non-digit
        }

        var number: Any? = self as Any?
        do {
            try ZMPhoneNumberValidator.validateValue(&number)
            return number as? String
        } catch {
            return nil
        }
    }

    /// Returns a normalized email or nil
    var validatedEmail: String? {
        var email: Any? = self as Any?
        do {
            try ZMEmailAddressValidator.validateValue(&email)
            return email as? String
        } catch {
            return nil
        }
    }
}

// MARK: - Utilities

let addressBookContactsSearchLimit = 2000

extension String {

    /// Returns the base64 encoded string of the SHA hash of the string
    var base64EncodedSHADigest: String {
        return Data(self.utf8).zmSHA256Digest().base64EncodedString(options: [])
    }

}

/// Private AB processing queue
let addressBookProcessingQueue = DispatchQueue(label: "Address book processing", attributes: [])

extension Sequence {

    /// Returns the elements of the sequence in the positions indicated by the range
    func elements(_ range: Range<UInt>) -> AnyIterator<Self.Iterator.Element> {

        var generator = self.makeIterator()
        var count: UInt = 0

        return AnyIterator {

            while count < range.lowerBound {
                if generator.next() != nil {
                    count += 1
                    continue
                } else {
                    return nil
                }
            }
            if count == range.upperBound {
                return nil
            }
            count += 1
            return generator.next()
        }
    }
}

// Generic contactto abstract actual address book framework details
protocol ContactRecord {

    var rawEmails: [String] { get }
    var rawPhoneNumbers: [String] { get }
    var firstName: String { get }
    var lastName: String { get }
    var middleName: String { get }
    var nickname: String { get }
    var organization: String { get }
    var localIdentifier: String { get }

}

extension ContactRecord {

    var displayName: String {
        return [self.firstName, self.middleName, self.lastName]
            .filter { $0 != "" }
            .joined(separator: " ")
    }
}

extension ZMAddressBookContact {

    convenience init?(contact: ContactRecord,
                      phoneNumberNormalizer: AddressBook.Normalizer) {
        self.init()

        // names
        self.firstName = contact.firstName
        self.lastName = contact.lastName
        self.middleName = contact.middleName
        self.nickname = contact.nickname
        self.organization = contact.organization
        self.emailAddresses = contact.rawEmails.compactMap { $0.validatedEmail }
        self.rawPhoneNumbers = contact.rawPhoneNumbers
        self.phoneNumbers = self.rawPhoneNumbers.compactMap { phoneNumberNormalizer($0) }
        self.localIdentifier = contact.localIdentifier

        // ignore contacts with no email nor phones
        guard self.emailAddresses.count > 0 || self.phoneNumbers.count > 0 else {
            return nil
        }
    }
}
