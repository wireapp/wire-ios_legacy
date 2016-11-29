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
    
    func sutForUser(incoming: Bool = false, outgoing: Bool = false, commonConnectionsCount: UInt = 0) -> UserConnectionView {
        let user = MockUserCopyable.mockUsers().first!
        let mockUser = getMockUser(user: user)
        mockUser.isPendingApprovalByOtherUser = outgoing
        mockUser.isPendingApprovalBySelfUser = incoming
        mockUser.isConnected = !outgoing && !incoming
        
        let connectionView = UserConnectionView(user: user)
        connectionView.commonConnectionsCount = commonConnectionsCount
        
        connectionView.layoutForTest()
        CASStyler.default().styleItem(connectionView)
        
        // Give Classy time to style the view
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        
        return connectionView
    }

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }
    
    func copy(view: UserConnectionView) -> (UserConnectionView, MockUser) {
        let copy = view.copy()
        let mockUser = getMockUser(user: view.user)
        let copyMockUser = MockUserCopyable(instance: mockUser)
        copy.user = (copyMockUser as AnyObject) as! ZMUser
        
        return (copy, copyMockUser)
    }
    
    func testVerifyCombinations() {
        let incomingMutation = { (view: UserConnectionView, value: Bool) -> UserConnectionView in
            let (newView, mockUser) = self.copy(view: view)
            mockUser.isConnected = value
            newView.user = (mockUser as AnyObject) as! ZMUser
            return newView
        }
        let boolCombinations = Set<Bool>(arrayLiteral: true, false)
        
        let incomingMutator = Mutator(applicator: incomingMutation, combinations: boolCombinations)
        
        let outgoingMutation = { (view: UserConnectionView, value: Bool) -> UserConnectionView in
            let (newView, mockUser) = self.copy(view: view)
            mockUser.isPendingApprovalByOtherUser = value
            newView.user = (mockUser as AnyObject) as! ZMUser
            return newView
        }
		
        let outgoingMutator = Mutator(applicator: outgoingMutation, combinations: boolCombinations)
        
        let showNameMutation = { (view: UserConnectionView, value: Bool) -> UserConnectionView in
            let (newView, _) = self.copy(view: view)
            newView.showUserName = value
            return newView
        }
        
        let showNameMutator = Mutator(applicator: showNameMutation, combinations: boolCombinations)
        
        let commonConnectionsMutation = { (view: UserConnectionView, value: Bool) -> UserConnectionView in
            let (newView, _) = self.copy(view: view)
            newView.commonConnectionsCount = value ? 0 : 10
            return newView
        }
        
        let commonConnectionsMutator = Mutator(applicator: commonConnectionsMutation, combinations: boolCombinations)
        
        let combinator = CombinationTest(mutable: self.sutForUser(), mutators: [incomingMutator, outgoingMutator, showNameMutator, commonConnectionsMutator])
        
        XCTAssertEqual(combinator.testAll {
            let identifier = "\($0.combinationChain)"
            print("Testing combination " + identifier)
            $0.result.layoutForTest()
            self.verify(view: $0.result, identifier: identifier)
            return .none
        }.count, 0)
        
    }
}
