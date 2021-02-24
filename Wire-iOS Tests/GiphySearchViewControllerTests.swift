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
import Ziphy

final class GiphySearchViewControllerTests: XCTestCase {

    weak var sut: GiphySearchViewController!

    var mockConversation: MockConversation!
    var client: ZiphyClient!
    var requester: MockURLSession!
    var resultsController: ZiphySearchResultsController!

    override func setUp() {
        super.setUp()

        mockConversation = MockConversation.oneOnOneConversation()
        requester = MockURLSession(cache: nil)
        client = ZiphyClient(host: "localhost", requester: requester, downloadSession: requester)
        resultsController = ZiphySearchResultsController(client: client, pageSize: 5)
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil
        client = nil
        requester = nil
        super.tearDown()
    }

    func testGiphySearchViewControllerIsNotRetainedAfterTimerIsScheduled(){
        autoreleasepool{
            // GIVEN
            let searchTerm: String = "apple"

            var giphySearchViewController: GiphySearchViewController! = GiphySearchViewController(searchTerm: searchTerm, conversation: (mockConversation as Any) as! ZMConversation, searchResultsController: resultsController)
            sut = giphySearchViewController

            // WHEN
            giphySearchViewController.performSearchAfter(delay: 0.1)
            giphySearchViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }

}
