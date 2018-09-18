//
//  MentionsSearchResultsViewControllerTests.swift
//  Wire-iOS-Tests
//
//  Created by Nicola Giancecchi on 12.09.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest
@testable import Wire

class MentionsSearchResultsViewControllerTests: CoreDataSnapshotTestCase {

    var sut: MentionsSearchResultsViewController!
    
    override func setUp() {
        super.setUp()
        sut = MentionsSearchResultsViewController(nibName: nil, bundle: nil)
        
        sut.viewDidLoad()
        self.recordMode = true
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testViewController() {
        sut.reloadTable(with: [selfUser, otherUser])
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    
}
