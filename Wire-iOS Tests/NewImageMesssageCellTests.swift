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

import UIKit
@testable import Wire

class NewImageMesssageCellTests: ZMSnapshotTestCase {
    
    var sut: NewImageMessageCell!
    var message: ZMConversationMessage!
    var context: MessageCellContext!
    var configuration: DefaultMessageCellConfiguration!
    
    override func setUp() {
        super.setUp()
                
        configuration = DefaultMessageCellConfiguration(.showSender)
        context = MessageCellContext(isSameSenderAsPrevious: false,
                                     isLastMessageSentBySelfUser: false,
                                     isTimeIntervalSinceLastMessageSignificant: false,
                                     isFirstMessageOfTheDay: false,
                                     isFirstUnreadMessage: false)
    }
    
    override func tearDown() {
        sut = nil
        message = nil
        
        super.tearDown()
    }
    
    func testLargeImage() {
        message = MockMessageFactory.imageMessage(with: self.image(inTestBundleNamed: "unsplash_burger.jpg"))!
        
        sut = NewImageMessageCell(from: configuration)
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(with: DefaultMessageCellContent(message: message, context: context))
        sut.widthAnchor.constraint(equalToConstant: 375).isActive = true
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        sut.prepareForSnapshot()
        
        verify(view: sut)
    }
    
    func testSmallImage() {
        message = MockMessageFactory.imageMessage(with: self.image(inTestBundleNamed: "unsplash_small.jpg"))!
        
        sut = NewImageMessageCell(from: configuration)
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(with: DefaultMessageCellContent(message: message, context: context))
        sut.widthAnchor.constraint(equalToConstant: 375).isActive = true
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        sut.prepareForSnapshot()
        
        verify(view: sut)
    }
}

