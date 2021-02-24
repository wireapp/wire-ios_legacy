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

class UserClientCellTests: ZMSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func cell(_ configuration: (UserClientCell) -> Void) -> UserClientCell {
        let cell = UserClientCell(frame: CGRect(x: 0, y: 0, width: 320, height: 64))
        configuration(cell)
        cell.layoutIfNeeded()
        return cell
    }
    
    func testUnverifiedFullWidthIdentifierLongerThan_16_Characters() {
        let client = MockUserClient()
        client.remoteIdentifier = "102030405060708090"
        client.deviceClass = .tablet
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: client)
        }))
    }
    
    func testUnverifiedTruncatedIdentifier() {
        let client = MockUserClient()
        client.remoteIdentifier = "807060504030201"
        client.deviceClass = .desktop
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: client)
        }))
    }
    
    func testUnverifiedTruncatedIdentifierMultipleCharactersMissing() {
        let client = MockUserClient()
        client.remoteIdentifier = "7060504030201"
        client.deviceClass = .desktop
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: client)
        }))
    }
    
    func testVerified() {
        let client = MockUserClient()
        client.remoteIdentifier = "7060504030201"
        client.deviceClass = .desktop
        client.verified = true
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: client)
        }))
    }
    
    func testLegalHold() {
        let client = MockUserClient()
        client.remoteIdentifier = "7060504030201"
        client.deviceClass = .legalHold
        client.verified = true
        
        verifyInAllColorSchemes(view: cell({ (cell) in
            cell.configure(with: client)
        }))
    }
    
}
