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
import WireLinkPreview
@testable import Wire

class ConversationTextMessageCellTests: CoreDataSnapshotTestCase {

    func testThatItDoesNotGenerateLinkPreviewForSoundCloudMessage() {
        // GIVEN
        let url = "https://soundcloud.com/fatma-alraeesi/moving-parts-trixie-mattel"
        let message = MockMessageFactory.textMessage(withText: url)!
        message.backingTextMessageData.linkPreview = LinkMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 0)

        // WHEN
        let cellTypes: [AnyClass] = ConversationTextMessageCellDescription.cells(for: message, searchQueries: []).map(\.baseType)

        // THEN
        let expectedCellTypes: [AnyClass] = [ConversationTextMessageCellDescription.self, ConversationSoundCloudCellDescription<AudioTrackViewController>.self]
        XCTAssertArrayEqual(cellTypes, expectedCellTypes)
    }

}
