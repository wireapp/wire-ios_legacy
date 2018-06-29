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
    
    func testThatItRendersMessageTimerSystemMessage_None_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .none)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_TenSeconds_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .tenSeconds)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_FiveMinutes_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .fiveMinutes)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneHour_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .oneHour)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneDay_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .oneDay)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneWeek_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .oneWeek)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_FourWeeks_Other() {
        let timerCell = cell(fromSelf: false, messageTimer: .fourWeeks)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_None_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .none)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_TenSeconds_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .tenSeconds)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_FiveMinutes_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .fiveMinutes)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneHour_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .oneHour)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneDay_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .oneDay)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_OneWeek_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .oneWeek)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    func testThatItRendersMessageTimerSystemMessage_FourWeeks_Self() {
        let timerCell = cell(fromSelf: true, messageTimer: .fourWeeks)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    // MARK: - Helper
    
    private func cell(fromSelf: Bool, messageTimer: MessageDestructionTimeoutValue) -> IconSystemCell {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let message = conversation.appendMessageTimerUpdateMessage(fromUser: fromSelf ? selfUser : otherUser, timer: messageTimer.rawValue, timestamp: Date())
        
        let cell = MessageTimerUpdateCell(style: .default, reuseIdentifier: name)
        cell.layer.speed = 0
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
