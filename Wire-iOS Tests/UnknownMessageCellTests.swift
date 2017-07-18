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

class UnknownMessageCellTests: ZMSnapshotTestCase {
    
    func wrappedCell() -> UITableView {
        
        let systemMessage = MockMessageFactory.systemMessage(with: .usingNewDevice, users: 1, clients: 1)
        
        let cell = UnknownMessageCell(style: .default, reuseIdentifier: "test")
        
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        
        cell.prepareForReuse()
        cell.layer.speed = 0 // freeze animations for deterministic tests
        cell.bounds = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 9999)
        cell.contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 320, height: 9999)
        
        cell.layoutMargins = UIEdgeInsetsMake(0, CGFloat(WAZUIMagic.float(forIdentifier: "content.left_margin")),
                                              0, CGFloat(WAZUIMagic.float(forIdentifier: "content.right_margin")))
        
        cell.configure(for: systemMessage, layoutProperties: layoutProperties)
        
        return cell.wrapInTableView()
    }
    
    func testCell() {
        verify(view: wrappedCell())
    }
    
}
