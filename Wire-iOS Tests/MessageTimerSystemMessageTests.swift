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
        //self.recordMode = true
        super.setUp()
    }
    
    
    func testThatItRendersMessageTimerSystemMessage() {
        let timerCell = cell(fromSelf: false, messageTimer: 50.0, expanded: false)
        verify(view: timerCell.prepareForSnapshots())
    }
    
    // MARK: - Helper
    
    private func cell(fromSelf: Bool, messageTimer: Double, expanded: Bool = false) -> IconSystemCell {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let message = conversation.appendMessageTimerUpdateMessage(fromUser: fromSelf ? selfUser : otherUser, timer: messageTimer)
        
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
