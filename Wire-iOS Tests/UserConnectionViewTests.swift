//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import Wire

func getMockUser(user: AnyObject) -> MockUserCopyable {
    if let mockUser = (user) as? MockUserCopyable {
        return mockUser
    }
    else {
        fatalError()
    }
}

extension UIView {
    func layoutForTest(in size: CGSize = CGSize(width: 320, height: 480)) {
        let fittingSize = self.systemLayoutSizeFitting(size)
        self.frame = CGRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height)
    }
}

final class MockUserCopyable: MockUser, Copyable {
    internal convenience init(instance: MockUserCopyable) {
        self.init(jsonObject: [:])
        self.name = instance.name
        self.emailAddress = instance.emailAddress
        self.phoneNumber = instance.phoneNumber
        self.handle = instance.handle
        self.accentColorValue = instance.accentColorValue
        self.isBlocked = instance.isBlocked
        self.isIgnored = instance.isIgnored
        self.isPendingApprovalByOtherUser = instance.isPendingApprovalByOtherUser
        self.isPendingApprovalBySelfUser = instance.isPendingApprovalBySelfUser
        self.isConnected = instance.isConnected
        self.isSelfUser = instance.isSelfUser
        self.connection = instance.connection
        self.contact = instance.contact
        self.remoteIdentifier = instance.remoteIdentifier
    }
    
    required init!(jsonObject: [AnyHashable : Any]!) {
        super.init(jsonObject: jsonObject)
    }

}

final class UserConnectionViewTests: ZMSnapshotTestCase {
    
    func sutForUser(_ user: ZMUser = MockUserCopyable.mockUsers().first!) -> UserConnectionView {
        let mockUser = getMockUser(user: user)
        mockUser.isPendingApprovalByOtherUser = true
        mockUser.isPendingApprovalBySelfUser = false
        mockUser.isConnected = false
        mockUser.isTeamMember = false
        
        let connectionView = UserConnectionView(user: user)
        connectionView.layoutForTest()

        return connectionView
    }

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }
    
    func copy(view: UserConnectionView) -> (UserConnectionView, MockUser) {
        let copy = view.copyInstance()
        let mockUser = getMockUser(user: view.user)
        let copyMockUser = MockUserCopyable(instance: mockUser)
        copy.user = (copyMockUser as AnyObject) as! ZMUser

        return (copy, copyMockUser)
    }
    
    func testWithUserName() {
        let sut = sutForUser()
        sut.layoutForTest()
        verify(view: sut)        
    }

    func testWithoutUserName() {
        // The last mock user does not have a handle
        let user = MockUserCopyable.mockUsers().last!
        let sut = sutForUser(user)
        sut.layoutForTest()
        verify(view: sut)
    }
    
}
