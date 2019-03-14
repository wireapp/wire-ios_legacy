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

//
//    var sut: ConversationContentViewController!
//    var mockZMUserSession: MockZMUserSession!
//    var mockMessage: MockMessage!
//
//    override func setUp() {
//        super.setUp()
//
//        mockConversation = createTeamGroupConversation()



final class ConnectRequestsViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: ConnectRequestsViewController!
    var mockConversation: ZMConversation!

    override func setUp() {
        super.setUp()
        sut = ConnectRequestsViewController()
        sut.connectionRequests = [mockConversation]

//        sut.view.frame = CGRect(origin: .zero, size: CGSize.iPhoneSize.iPhone4_7)

        /// TODO: remove this after snapshot is created
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState(){
        verifyInIPhoneSize(view: sut.view)
    }
}
