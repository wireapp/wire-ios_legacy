//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension CoreDataFixture {
    func mockUserClient(fingerprintString: String = "102030405060708090102030405060708090102030405060708090") -> UserClient! {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "102030405060708090"

        client.user = ZMUser.insertNewObject(in: uiMOC)
        client.deviceClass = .tablet
        client.model = "Simulator"
        client.label = "Bill's MacBook Pro"

        let fingerprint: Data? = fingerprintString.data(using: .utf8)

        client.fingerprint = fingerprint

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let activationDate = formatter.date(from: "2016/05/01 14:31")

        client.activationDate = activationDate

        return client
    }
}
