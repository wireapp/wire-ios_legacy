//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class LegalHoldAlertFactoryTests: XCTestCase {

    var user: MockUserType!

    override func setUp() {
        super.setUp()
        user = MockUserType.createSelfUser(name: "Bob the Builder", inTeam: UUID())
    }

    override func tearDown() {
        user = nil
        super.tearDown()
    }

    func testThatItCanCreateLegalHoldActivatedAlert() {
        let alert = LegalHoldAlertFactory.makeLegalHoldActivatedAlert(for: user, suggestedStateChangeHandler: nil)
        verify(matching: alert)
    }

    func testThatItCanCreateLegalHoldDeactivatedAlert() {
        let alert = LegalHoldAlertFactory.makeLegalHoldDeactivatedAlert(for: user, suggestedStateChangeHandler: nil)
        verify(matching: alert)
    }

    func testThatItCanCreateLegalHoldPendingAlert() {
        let prekey = LegalHoldRequest.Prekey(id: 65535, key: Data(base64Encoded: "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g==")!)
        let request = LegalHoldRequest(target: UUID(), requester: UUID(), clientIdentifier: "eca3c87cfe28be49", lastPrekey: prekey)
        let alert = LegalHoldAlertFactory.makeLegalHoldActivationAlert(for: request, user: user, suggestedStateChangeHandler: nil)
        verify(matching: alert)
    }
}
