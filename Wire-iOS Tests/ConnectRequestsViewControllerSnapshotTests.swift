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
import SnapshotTesting

final class MockCnnectionRequest: ConnectionRequest {
    var connectedUser: UserType?
}

final class ConnectRequestsViewControllerSnapshotTests: XCTestCase {
    
    var sut: ConnectRequestsViewController!
    var mockConversation: MockConversation!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)

        sut = ConnectRequestsViewController()

        sut.loadViewIfNeeded()

        let mockCnnectionRequest = MockCnnectionRequest()
        let mockUser = MockUserType.createSelfUser(name: "Bruno")
        mockUser.accentColorValue = .brightOrange
        mockUser.handle = "bruno"
        mockCnnectionRequest.connectedUser = mockUser
        
        sut.connectionRequests = [mockCnnectionRequest]
        sut.reload()

        sut.view.frame = CGRect(origin: .zero, size: CGSize.iPhoneSize.iPhone4_7)
    }
    
    override func tearDown() {
        sut = nil
        mockConversation = nil

        super.tearDown()
    }

    func testForOneRequest() {
        verify(matching: sut)
    }

    /*func testForTwoRequests() {
        let otherUser = MockUserType.createUser(name: "Bill")
        otherUser.accentColorValue = .brightYellow
        
        let requestConversation = MockConversation.oneOnOneConversation()
        
        sut.connectionRequests = [requestConversation.convertToRegularConversation(), mockConversation.convertToRegularConversation()]
        sut.reload(animated: false)
        
        verify(matching: sut)
    }*/
}
