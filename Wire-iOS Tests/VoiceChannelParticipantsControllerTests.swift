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

import XCTest
@testable import Wire

final class VoiceChannelParticipantsControllerTests: XCTestCase {
    
    var sut: VoiceChannelParticipantsController!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }



    /// Example checker method which can be reused in different tests
    ///
    /// - Parameters:
    ///   - file: optional, for XCTAssert logging error source
    ///   - line: optional, for XCTAssert logging error source
    fileprivate func checkerExample(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(true, file: file, line: line)
    }

    func testExample(){
        // GIVEN
        let mockCollectionView : UICollectionView
        let mockConversation = ZMConversation()
        sut = VoiceChannelParticipantsController(conversation: mockConversation, collectionView: mockCollectionView)

        // WHEN

        // THEN
        checkerExample()
    }
}
