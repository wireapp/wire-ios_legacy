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
@testable import WireSyncEngine

class AddressBookSearchTests: MessagingTest {

    var sut: WireSyncEngine.AddressBookSearch!
    var addressBook: MockAddressBook!

    override func setUp() {
        super.setUp()
        self.addressBook = MockAddressBook()
        self.sut = WireSyncEngine.AddressBookSearch(addressBook: self.addressBook)
    }

    override func tearDown() {
        self.sut = nil
        self.addressBook = nil
        super.tearDown()
    }
}

// MARK: - Search query
extension AddressBookSearchTests {

    func testThatItSearchesByNameWithMatch() {

        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olivia", emailAddresses: ["oli@example.com"], phoneNumbers: []),
            MockAddressBookContact(firstName: "Ada", emailAddresses: [], phoneNumbers: ["+155505012"])
        ]

        // when
        let result = Array(sut.contactsMatchingQuery("ivi", identifiersToExclude: []))

        // then
        XCTAssertEqual(result.count, 1)
        guard result.count == 1 else { return }
        XCTAssertEqual(result[0].emailAddresses, ["oli@example.com"])
    }

    func testThatItSearchesByNameWithMatchExcludingIdentifiers() {

        // given
        let identifier = "233124"
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olivia 1", emailAddresses: ["oli@example.com"], phoneNumbers: [], identifier: identifier),
            MockAddressBookContact(firstName: "Olivia 2", emailAddresses: [], phoneNumbers: ["+155505012"])
        ]

        // when
        let result = Array(sut.contactsMatchingQuery("ivi", identifiersToExclude: [identifier]))

        // then
        XCTAssertEqual(result.count, 1)
        guard result.count == 1 else { return }
        XCTAssertEqual(result[0].firstName, "Olivia 2")
    }

    func testThatItSearchesByNameWithNoMatch() {

        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olivia", emailAddresses: ["oli@example.com"], phoneNumbers: []),
            MockAddressBookContact(firstName: "Ada", emailAddresses: [], phoneNumbers: ["+155505012"])
        ]

        // when
        let result = Array(sut.contactsMatchingQuery("Nadia", identifiersToExclude: []))

        // then
        XCTAssertEqual(result.count, 0)
    }
}
