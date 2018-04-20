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

import Foundation
@testable import Wire

final class GiphySnapshotTests: ZMSnapshotTestCase {
    var sut: GiphySearchViewController!

    var mockConversation: MockConversation!
    var mockNavigationController: UINavigationController!

    override func setUp() {
        super.setUp()

        mockConversation = MockConversation.onoOnOneConversation()

        let searchTerm: String = "apple"
        sut = GiphySearchViewController(withSearchTerm: searchTerm, conversation: (mockConversation as Any) as! ZMConversation)
        mockNavigationController = sut.wrapInsideNavigationController()

        sut.collectionView?.backgroundColor = .white

        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil
        mockNavigationController = nil

        UIView.setAnimationsEnabled(true)

        super.tearDown()
    }

    func testEmptySearchScreenWithKeyword(){
        verify(view: mockNavigationController.view)
    }

    func testConfirmationScreenWithDisabledSendButton(){
        let data = self.data(forResource: "not_animated", extension: "gif")!
        let image = FLAnimatedImage(animatedGIFData: data)

        let confirmationController = sut.pushConfirmationViewController(ziph: nil, previewImage: image, animated: false)
        confirmationController.view.backgroundColor = .white

        verify(view: mockNavigationController.view)
    }
}
