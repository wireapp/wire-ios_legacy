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
import SnapshotTesting
@testable import Wire

extension XCTestCase {
    var snapshotDirectory: String {
        let path = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent

        return path
    }
}

final class VersionInfoViewControllerSnapshotTests: XCTestCase {
    
    var sut: VersionInfoViewController!

    override func setUp() {
        super.setUp()
        let path = Bundle(for: type(of: self)).path(forResource: "DummyComponentsVersions", ofType: "plist")!

        sut = VersionInfoViewController(versionsPlist: path)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState(){

        let failure = verifySnapshot(matching: sut, as: .image, snapshotDirectory: snapshotDirectory)

        XCTAssertNil(failure)
    }
}


final class UIAlertControllerCompanyLoginSnapshotTests: XCTestCase {
    var sut: UIAlertController!

    override func setUp() {
        super.setUp()
        sut = UIAlertController.companyLogin(prefilledCode: nil, validator: {_ -> Bool in
            return true
        }, completion: {_ in })

        addUIInterruptionMonitor(withDescription: "System Dialog") {
            (alert) -> Bool in
            alert.buttons["OK"].tap()
            return true
        }
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    ///TODO: find a solution to dismiss photo permission dialog first.
    func disable_testForAlert(){
        // notice: pass alert's view here othewise it is expand and fill the screen's size. We can create
        // extension Snapshotting where Value == UIAlertController, Format == UIImage
        // to fix it.
        let failure = verifySnapshot(matching: sut.view, as: .image, snapshotDirectory: snapshotDirectory)

        XCTAssertNil(failure)
    }

}
