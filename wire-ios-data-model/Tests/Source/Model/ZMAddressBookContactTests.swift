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
import XCTest

class ZMAddressBookContactTests: XCTestCase {

    func testThatTwoContactsAreTheSame() {

        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]

        // when
        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }

        // then
        XCTAssertEqual(contact1, contact2)
        XCTAssertEqual(contact1.hash, contact2.hash)
    }

    func testThatTwoContactsAreNotTheSameBecauseEmailIsNotSame() {

        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]

        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }

        // when
        contact2.emailAddresses = []

        // then
        XCTAssertNotEqual(contact1, contact2)
        XCTAssertNotEqual(contact1.hash, contact2.hash)

    }

    func testThatTwoContactsAreNotTheSameBecausePhoneIsNotSame() {

        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]

        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }

        // when
        contact2.phoneNumbers = []

        // then
        XCTAssertNotEqual(contact1, contact2)
        XCTAssertNotEqual(contact1.hash, contact2.hash)

    }

    func testThatTwoContactsAreNotTheSameBecauseNameIsNotSame() {

        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]

        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }

        // when
        contact2.lastName = "Licci"

        // then
        XCTAssertNotEqual(contact1, contact2)
        XCTAssertNotEqual(contact1.hash, contact2.hash)
    }

}
