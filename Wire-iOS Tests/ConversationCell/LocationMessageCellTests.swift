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

class LocationMessageCellTests: ConversationCellSnapshotTestCase {

    override func setUp() {
        super.setUp()
    }

    typealias CellConfiguration = (MockMessage) -> Void

    func testThatItRendersLocationCellWithAddressCorrect() {
        // This is experimental as the MKMapView might break the snapshot tests,
        // If it does we can try to use the 'withAccurancy' methods in FBSnapshotTestCase
        verify(message: makeMessage())
    }
    
    func testThatItRendersLocationCellWithoutAddressCorrect() {
        verify(message: makeMessage {
            $0.backingLocationMessageData.name = nil
        })
    }

    func testThatItRendersLocationCellObfuscated() {
        verify(message: makeMessage {
            $0.isObfuscated = true
        })
    }

    // MARK: - Helpers

    func makeMessage(_ config: CellConfiguration? = nil) -> MockMessage {
        let locationMessage = MockMessageFactory.locationMessage()!
        locationMessage.backingLocationMessageData?.latitude = 9.041169
        locationMessage.backingLocationMessageData?.longitude = 48.53775
        locationMessage.backingLocationMessageData?.name = "Berlin, Germany"
        
        config?(locationMessage)
        return locationMessage
    }
    
}
