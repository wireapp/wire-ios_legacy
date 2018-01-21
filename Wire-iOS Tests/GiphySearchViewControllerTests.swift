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
    let searchTerm: String = "apple"

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

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

            var giphySearchViewController: GiphySearchViewController! = GiphySearchViewController(withSearchTerm: searchTerm, conversation: (mockConversation as Any) as! ZMConversation)
            sut = giphySearchViewController


            // WHEN
            giphySearchViewController.performSearchAfter(delay: 0.1)
            giphySearchViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }

    func testThatRootViewControllerPresentAndDismissNavigationControllerDoesNotRetain() {
        
        weak var sutNavi: UINavigationController!
        var strongGiphySearchViewController:GiphySearchViewController!
        
        autoreleasepool{
            // GIVEN
            let window = (UIApplication.shared.delegate as! AppDelegate).window
            window.rootViewController = UIViewController()
            
            let giphySearchViewController: GiphySearchViewController! = GiphySearchViewController(withSearchTerm: searchTerm, conversation: (mockConversation as Any) as! ZMConversation)
            sut = giphySearchViewController
            strongGiphySearchViewController = giphySearchViewController
            
            
            let navigationController = giphySearchViewController.wrapInsideNavigationController()
            sutNavi = navigationController
            
            
            window.makeKeyAndVisible()
            window.rootViewController?.viewDidAppear(false)
            
            let exp = expectation(description: "Wait for present and dismiss")
            
            // WHEN
            window.rootViewController?.present(navigationController, animated: false){
                XCTAssertNotNil(giphySearchViewController.view)
                giphySearchViewController.viewDidAppear(false)
                
                XCTAssertNotNil(sutNavi)
                XCTAssertNotNil(self.sut)
                
                navigationController.dismiss(animated: false){
                    window.rootViewController?.viewDidAppear(false)
                    XCTAssertNotNil(sutNavi)
                    XCTAssertNotNil(self.sut)
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // THEN
        XCTAssertNotNil(strongGiphySearchViewController)
        strongGiphySearchViewController = nil
        XCTAssertNil(sutNavi)
        XCTAssertNil(sut)
    }
}
