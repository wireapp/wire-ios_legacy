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
import MapKit

class LocationMessageCellTests: ZMSnapshotTestCase {

    typealias CellConfiguration = (MockMessage) -> Void

    func testThatItRendersLocationCellWithAddressCorrect() {
        // This is experimental as the MKMapView might break the snapshot tests,
        // If it does we can try to use the 'withAccurancy' methods in FBSnapshotTestCase
        verify(view: wrappedCellWithConfig())
    }
    
    func testThatItRendersLocationCellWithoutAddressCorrect() {
        verify(view: wrappedCellWithConfig {
            $0.backingLocationMessageData.name = nil
        })
    }

    func testThatItRendersLocationCellObfuscated() {
        verify(view: wrappedCellWithConfig {
            $0.isObfuscated = true
        })
    }

    // MARK: - Helper

    func wrappedCellWithConfig(_ config: CellConfiguration? = nil) -> UITableView {
        let fileMessage = MockMessageFactory.locationMessage()
        fileMessage?.backingLocationMessageData?.latitude = 9.041169
        fileMessage?.backingLocationMessageData?.longitude = 48.53775
        fileMessage?.backingLocationMessageData?.name = "Berlin, Germany"
        
        config?(fileMessage!)
        
        let cell = LocationMessageCell(style: .default, reuseIdentifier: String(describing: LocationMessageCell.self))
        cell.backgroundColor = UIColor.white
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
        
        cell.configure(for: fileMessage, layoutProperties: layoutProperties)
        
        return cell.wrapInTableView()
    }
    
}
