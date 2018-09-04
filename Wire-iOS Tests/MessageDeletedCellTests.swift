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


import XCTest
@testable import Wire

class MessageDeletedCellTests: ZMSnapshotTestCase {

    var sut: MessageDeletedCell!
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = UIColor.white
        sut = MessageDeletedCell(style: .default, reuseIdentifier: nil)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersMessageDeletedCellCorrect() {
        configure(cell: sut)
        verify(view: sut)
    }

    /// TODO: This test currently fails on CI and should be enabled again
    /// as soon as we have set up https://github.com/ashfurrow/second_curtain
    func disabled_testThatItRendersMessageDeletedCellCorrect_Selected() {
        sut.setSelected(true, animated: false)
        configure(cell: sut)
        verify(view: sut)
    }

}

extension MessageDeletedCellTests {

    func configure(cell: MessageDeletedCell) {
        let message = MockMessageFactory.systemMessage(with: .messageDeletedForEveryone, users: 0, clients: 0)
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        
        cell.layoutMargins = UIView.directionAwareConversationLayoutMargins
        cell.layer.speed = 0
        cell.configure(for: message, layoutProperties: layoutProperties)
        
        let size = cell.systemLayoutSizeFitting(CGSize(width: 375, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        cell.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }

}
