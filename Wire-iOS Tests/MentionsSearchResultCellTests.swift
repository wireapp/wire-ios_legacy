//
//  MentionsSearchResultCellTests.swift
//  Wire-iOS-Tests
//
//  Created by Nicola Giancecchi on 12.09.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest
@testable import Wire

class MentionsSearchResultCellTests: CoreDataSnapshotTestCase {

    var sut: MentionsSearchResultCell!
    var user: ZMUser!
    
    override func setUp() {
        super.setUp()
        sut = MentionsSearchResultCell(style: .default, reuseIdentifier: "reuseIdentifier")
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        sut.bounds = CGRect(x: 0, y: 0, width: 320, height: 56)
        self.recordMode = true
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testResultCell() {
        sut.configure(with: otherUser)
        let view = sut.wrapInTableView()
        verify(view: view)
    }
    
}



