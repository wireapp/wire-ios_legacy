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

final class InviteContactsViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: InviteContactsViewController!
    
    override func setUp() {
        super.setUp()
        sut = InviteContactsViewController()

        /// TODO: remove this after snapshot is created
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForShareContactsViewControllerShown() {
        verify(view: sut.view)
    }

    func testForNoResult(){
//        let _ = sut.view
//        sut.dismiss(animated: false, completion: nil)

        if let childVC = sut.childViewControllers.first as? ShareContactsViewController {
            childVC.formStepDelegate.didCompleteFormStep(sut)
        }

        verify(view: sut.view)
    }


    func testForContactsAreShown(){
        sut.dismiss(animated: false, completion: nil)

        verify(view: sut.view)
    }
}
