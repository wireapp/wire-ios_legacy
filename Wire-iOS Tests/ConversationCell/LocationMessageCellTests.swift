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

final class LocationMessageCellTests: ConversationCellSnapshotTestCase {

    typealias CellConfiguration = (MockMessage) -> Void

    var sut: ImageMessageView!
    
    override func setUp() {
        super.setUp()
        
        mockSelfUser.name = "selfUser"
        mockSelfUser.accentColorValue = .vividRed
    }
    
    /// Disabled since the MKMApView makes the test flaky (The map view is black when running on local machine)
    func disabled_testThatItRendersLocationCellWithAddressCorrect() {
        // This is experimental as the MKMapView might break the snapshot tests,
        verify(message: makeMessage())
    }

    /// Disabled since the MKMApView makes the test flaky
    func disabled_testThatItRendersLocationCellWithoutAddressCorrect() {
        verify(message: makeMessage {
            $0.backingLocationMessageData.name = nil
        })
    }

    func testThatItRendersLocationCellObfuscated() {
        verify(message: makeMessage() {
            $0.isObfuscated = true
        })
    }

    // MARK: - Helpers

    private func makeMessage(_ config: CellConfiguration? = nil) -> MockMessage {
        let locationMessage = MockMessageFactory.locationMessage(sender: mockSelfUser)!
        locationMessage.backingLocationMessageData?.name = "Berlin, Germany"

        config?(locationMessage)
        return locationMessage
    }

}
