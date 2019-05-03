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


final class ConnectRequestsViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: ConnectRequestsViewController!
    var mockConversation: ZMConversation!

    override func setUp() {
        super.setUp()
        sut = ConnectRequestsViewController()

        sut.loadViewIfNeeded()

        mockConversation = otherUserConversation

        sut.connectionRequests = [mockConversation!]
        sut.reload()

        sut.view.frame = CGRect(origin: .zero, size: CGSize.iPhoneSize.iPhone4_7)
    }
    
    override func tearDown() {
        sut = nil
        mockConversation = nil
        
        super.tearDown()
    }

    func testForInitState(){
        verifyInIPhoneSize(view: sut.view)
    }
}
