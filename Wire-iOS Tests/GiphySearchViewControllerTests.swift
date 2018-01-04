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

final class GiphySearchViewControllerTests: XCTestCase {
    
    weak var sut: GiphySearchViewController!
    var mockConversation: MockConversation!

    override func setUp() {
        super.setUp()

        mockConversation = MockConversation()
        mockConversation.conversationType = .oneOnOne
        mockConversation.displayName = "John Doe"
        mockConversation.connectedUser = MockUser.mockUsers().last!
    }
    
    override func tearDown() {
        sut = nil
        mockConversation = nil
        super.tearDown()
    }

    func testGiphySearchViewControllerIsNotRetainedAfterTimerIsScheduled(){
        autoreleasepool{
            // GIVEN
            let searchTerm: String = "apple"

            var giphySearchViewController: GiphySearchViewController! = GiphySearchViewController(withSearchTerm: searchTerm, conversation: (mockConversation as Any) as! ZMConversation)
            sut = giphySearchViewController


            // WHEN
            giphySearchViewController.performSearchAfter(delay: 0.1)
            giphySearchViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }

}
