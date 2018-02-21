//
//  GroupDetailsParticipantCellTests.swift
//  Wire-iOS-Tests
//
//  Created by Jacob on 21.02.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest
@testable import Wire

class GroupDetailsParticipantCellTests: ZMSnapshotTestCase {
        
    override func setUp() {
        super.setUp()
        
        recordMode = true
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func cell(_ configuration : (GroupDetailsParticipantCell) -> Void) -> GroupDetailsParticipantCell {
        let cell = GroupDetailsParticipantCell(frame: CGRect(x: 0, y: 0, width: 320, height: 48))
        
        configuration(cell)
        
        cell.layoutIfNeeded()
        
        return cell
    }
    
    func testNonTeamUser() {
        let user = MockUser.mockUsers()[0]
        
        let moo = cell({ (cell) in
            cell.configure(with: user)
        })
        
        verify(view: moo)
    }
    
}
