//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


class MessageTimerSystemMessageTests: CoreDataSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        self.recordMode = true
    }
    
    func testThatItRendersMessageTimerSystemMessage_None() {
        let timerCell = cell(fromSelf: false, messageTimer: .none, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_TenSeconds() {
        let timerCell = cell(fromSelf: false, messageTimer: .tenSeconds, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_FiveMinutes() {
        let timerCell = cell(fromSelf: false, messageTimer: .fiveMinutes, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneHour() {
        let timerCell = cell(fromSelf: false, messageTimer: .oneHour, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneDay() {
        let timerCell = cell(fromSelf: false, messageTimer: .oneDay, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneWeek() {
        let timerCell = cell(fromSelf: false, messageTimer: .oneWeek, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_FourWeeks() {
        let timerCell = cell(fromSelf: false, messageTimer: .fourWeeks, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    // MARK: - Helper
    
    private func cell(fromSelf: Bool, messageTimer: MessageDestructionTimeoutValue, expanded: Bool = false) -> IconSystemCell {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let message = conversation.appendMessageTimerUpdateMessage(fromUser: fromSelf ? selfUser : otherUser, timer: messageTimer.rawValue)
        
        let cell = MessageTimerUpdateCell(style: .default, reuseIdentifier: name)
        cell.layer.speed = 0
        if expanded {
            cell.setSelected(true, animated: false)
        }
        let props = ConversationCellLayoutProperties()
        
        cell.configure(for: message, layoutProperties: props)
        return cell
    }
}



private extension UITableViewCell {
    
    func prepareForSnapshots() -> UIView {
        setNeedsLayout()
        layoutIfNeeded()
        
        bounds.size = systemLayoutSizeFitting(
            CGSize(width: 320, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        return wrapInTableView()
    }
    
}
