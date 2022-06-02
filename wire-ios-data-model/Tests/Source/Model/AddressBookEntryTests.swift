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

import XCTest
import WireUtilities
import Contacts

class AddressBookEntryTests: ZMBaseManagedObjectTest {

    func testThatItReturnsTrackedKeys() {

        // GIVEN
        let entry = AddressBookEntry.insertNewObject(in: self.uiMOC)

        // WHEN
        let keys = entry.keysTrackedForLocalModifications()

        // THEN
        XCTAssertTrue(keys.isEmpty)
    }

    @available(iOS 9.0, *)
    func testThatItCreatesEntryFromContact() {

        // GIVEN
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let contact = CNMutableContact()
        contact.familyName = "TheFamily"
        contact.givenName = "MyName"
        contact.emailAddresses.append(CNLabeledValue(label: "home", value: "foo@example.com"))
        contact.phoneNumbers.append(CNLabeledValue(label: "home", value: CNPhoneNumber(stringValue: "+15557654321")))

        // WHEN
        let sut = AddressBookEntry.create(from: contact, managedObjectContext: self.uiMOC, user: user)

        // THEN
        XCTAssertEqual(sut.localIdentifier, contact.identifier)
        XCTAssertEqual(sut.cachedName, "MyName TheFamily")
        XCTAssertEqual(sut.user, user)

    }
}
