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

import XCTest
@testable import Wire

final class EmailAdresssValidatorTests: XCTestCase {

    func testThatValidEmailsPassValidation() {
        // GIVEN
        let validEmailAddresses =
        [
            "niceandsimple@example.com",
            "very.common@example.com",
            "a.little.lengthy.but.fine@dept.example.com",
             "disposable.style.email.with+symbol@example.com",
            "other.email-with-dash@example.com",
            "a@b.c.example.com",
            "a@3b.c.example.com",
            "a@b-c.d.example.com",
            "a@b-c.d-c.example.com",
            "a@b3-c.d4.example.com",
            "a@b-4c.d-c4.example.com",
            "meep.moop@example.com",
            "  some@email.com  ",
            /// edge case: detector removes leading "=" but say this is a valid email address
            /// "=?iso-8859-1?q?keld_j=f8rn_simonsen?=@example.com",
            "x@something_odd.example.com"
        ]

        // WHEN & THEN

        validEmailAddresses.forEach { email in
            XCTAssert(email.isEmail, "failed for \(email)")
        }
    }

    func testThatInvalidEmailsDoNotPassValidation() {
        // GIVEN
        let invalidEmailAddresses =
        ["Abc.example.com", // (an @ character must separate the local and domain parts)
        "A@b@c@example.com", // (only one @ is allowed outside quotation marks)
        "a\"b(c)d,e:f;g<h>i[j\\k]l@example.com", // (none of the special characters in this local part is allowed outside quotation marks)
        "just\"not\"right@example.com", // (quoted strings must be dot separated or the only element making up the local-part)
        "this is\"not\\allowed@example.com", // (spaces, quotes, and backslashes may only exist when within quoted strings and preceded by a backslash)
        "this\\ still\\\"not\\\\allowed@example.com", // (even if escaped (preceded by a backslash), spaces, quotes, and backslashes must still be contained by quotes)
        "tester@example..com", // double dot before @
        "foo..tester@example.com", // double dot after @
        "",
        "a@b",
        "a@b3",
        "a@b.c-",
        //      "a@3b.c", //unclear why this should be not valid
        "two words@something.org",
        "\"Meep Moop\" <\"The =^.^= Meeper\"@x.y",
        "mailbox@[11.22.33.44]",
        "some prefix with <two words@example.com>",
        "x@host.with?query=23&parameters=42",
        "some.mail@host.with.port:12345",
        "comments(inside the address)@are(actually).not(supported, but nobody uses them anyway)",
        "\"you need to close quotes@proper.ly",
        "\"you need\" <to.close@angle-brackets.too",
        "\"you need\" >to.open@angle-brackets.first",
        "\"you need\" <to.close@angle-brackets>.right",
        "some<stran>ge@example.com",
        "Mr. Stranger <some<stran>ge@example.com>",
        "<Meep.Moop@EXample.com>",
        "abc.\"defghi\".xyz@example.com",
        "\"abcdefghixyz\"@example.com",
        "user@localserver"
        ]

        // WHEN & THEN

        invalidEmailAddresses.forEach { email in
            XCTAssertFalse(email.isEmail, "failed for \(email)")
        }
    }
}
