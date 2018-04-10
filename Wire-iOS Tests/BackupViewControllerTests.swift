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

import Foundation
import XCTest
@testable import Wire

class MockBackupSource: BackupSource {
    func backupActiveAccount(password: Password, completion: @escaping SessionManager.BackupResultClosure) {
        
    }
}

class BackupViewControllerTests: ZMSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        self.snapshotBackgroundColor = .darkGray
    }
    
    func testInitialState() {
        // GIVEN
        let sut = BackupViewController(backupSource: MockBackupSource())
        // WHEN && THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testLoading() {
        // GIVEN
        let sut = BackupViewController(backupSource: MockBackupSource())
        sut.view.layer.speed = 0
        sut.tableView(UITableView(), didSelectRowAt: IndexPath(row: 1, section: 0))
        // WHEN && THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
}

