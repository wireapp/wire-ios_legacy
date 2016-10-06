//
//  TypingIndicatorViewTests.swift
//  Wire-iOS
//
//  Created by Jacob on 05/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest

@testable import Wire
import Classy
import Cartography

class TypingIndicatorViewTests: ZMSnapshotTestCase {

    var sut: TypingIndicatorView!
    
    override func setUp() {
        super.setUp()
        sut = TypingIndicatorView()
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.layer.speed = 0

        CASStyler.default().styleItem(sut)
    }
    
    func testOneTypingUser() {
        sut.typingUsers = Array(MockUser.mockUsers().prefix(1))
        sut.layoutIfNeeded()
        verify(view: sut)
    }
    
    func testTwoTypingUsers() {
        sut.typingUsers = Array(MockUser.mockUsers().prefix(2))
        sut.layoutIfNeeded()
        verify(view: sut)
    }
    
    func testManyTypingUsers() {
        // limit width to test overflow behaviour
        constrain(sut) { typingIndicator in
            typingIndicator.width == 320
        }
        
        sut.typingUsers = Array(MockUser.mockUsers().prefix(5))
        sut.layoutIfNeeded()
        verify(view: sut)
    }
}
