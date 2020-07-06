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

import Foundation
@testable import Wire

class CallParticipantsViewTests: ZMSnapshotTestCase {
    
    var sut: CallParticipantsViewController!
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    static func participants(count participantCount: Int, sendsVideo: Bool = false) -> CallParticipantsList {
        return (0..<participantCount)
            .lazy
            .map { MockUser.mockUsers()[$0] }
            .sorted { $0.name < $1.name }
            .map { CallParticipantsCellConfiguration.callParticipant(user: $0, sendsVideo: sendsVideo) }
    }
    
    func testCallParticipants_Overflowing_Light() {
        // When
        sut = CallParticipantsViewController(participants: type(of: self).participants(count: 10), allowsScrolling: true)
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        
        // Then
        verify(view: sut.view)
    }
    
    func testCallParticipants_Overflowing_Dark() {
        // When
        sut = CallParticipantsViewController(participants: type(of: self).participants(count: 10), allowsScrolling: true)
        sut.variant = .dark
        snapshotBackgroundColor = .black
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        
        // Then
        verify(view: sut.view)
    }
    
    func testCallParticipants_Truncated_Light() {
        // When
        sut = CallParticipantsViewController(participants: type(of: self).participants(count: 10), allowsScrolling: false)
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        
        // Then
        verify(view: sut.view)
    }
    
    func testCallParticipants_Truncated_Dark() {
        // When
        sut = CallParticipantsViewController(participants: type(of: self).participants(count: 10), allowsScrolling: false)
        sut.variant = .dark
        snapshotBackgroundColor = .black
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        
        // Then
        verify(view: sut.view)
    }
    
}
