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

final class GiphyConfirmationViewControllerSnapshotTests: ZMSnapshotTestCase {
    var sut: GiphyConfirmationViewController!

    var mockConversation: MockConversation!

    override func setUp() {
        super.setUp()

        mockConversation = MockConversation.oneOnOneConversation()

        let data = self.data(forResource: "not_animated", extension: "gif")!
        let image = FLAnimatedImage(animatedGIFData: data)

        sut = GiphyConfirmationViewController(withZiph: nil, previewImage: image, searchResultController: nil)
        sut.title = mockConversation.displayName.uppercased()
        sut.view.backgroundColor = .white
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil

        super.tearDown()
    }


    /// Notice: navigation bar is empty and it is differnet form the apperance on the app
    func testConfirmationScreenWithDisabledSendButton(){
        let navigationController = NavigationController(rootViewController: sut)
        verify(view: navigationController.view)
    }
}
