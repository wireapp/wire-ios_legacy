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
        snapshotBackgroundColor = .whiteColor()
        sut = MessageDeletedCell(style: .Default, reuseIdentifier: nil)
    }

    func testThatItRendersMessageDeletedCellCorrect() {
        configure(cell: sut)
        verify(view: sut)
    }

}

extension MessageDeletedCellTests {

    func configure(cell cell: MessageDeletedCell) -> MessageDeletedCell {
        let message = MockMessageFactory.systemMessageWithType(.MessageDeletedForEveryone, users: 0, clients: 0)
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        
        cell.layoutMargins = UIEdgeInsetsMake(0, CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin")),
                                             0, CGFloat(WAZUIMagic.floatForIdentifier("content.right_margin")))
        cell.configureForMessage(message, layoutProperties: layoutProperties)
        
        let size = cell.systemLayoutSizeFittingSize(CGSizeMake(320.0, 0.0), withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
        cell.bounds = CGRectMake(0.0, 0.0, size.width, size.height)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        return cell
    }

}
