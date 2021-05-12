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

final class ConversationLinkAttachmentMessageCellTests: XCTestCase {

    var mockThumbnail: MockImageResource!

    override func setUp() {
        super.setUp()
        let imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        mockThumbnail = MockImageResource()
        mockThumbnail.imageData = imageData.pngData()!
    }

    override func tearDown() {
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        mockThumbnail = nil
        super.tearDown()
    }

    func testThatItRendersYouTubeLinkAttachment() {
        // GIVEN
        let attachment = LinkAttachment(type: .youTubeVideo, title: "Lagar mat med Fernando Di Luca",
                                        permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
                                        thumbnails: [], originalRange: NSRange(location: 0, length: 43))

        mockThumbnail.cacheIdentifier = #function
        let configuration = ConversationLinkAttachmentCell.Configuration(attachment: attachment, thumbnailResource: mockThumbnail)

        // WHEN
        let cell = ConversationLinkAttachmentCell()
        cell.configure(with: configuration, animated: false)
        cell.frame.size = cell.systemLayoutSizeFitting(CGSize(width: 414, height: 0))

        // THEN
        verify(matching: cell)
    }

    func testThatItRendersSoundCloudSongAttachment() {
        // GIVEN
        let attachment = LinkAttachment(type: .soundCloudTrack, title: "Bridgit Mendler - Atlantis feat. Kaiydo",
                                        permalink: URL(string: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo")!,
                                        thumbnails: [], originalRange: NSRange(location: 0, length: 74))

        mockThumbnail.cacheIdentifier = #function
        let configuration = ConversationLinkAttachmentCell.Configuration(attachment: attachment, thumbnailResource: mockThumbnail)

        // WHEN
        let cell = ConversationLinkAttachmentCell()
        cell.configure(with: configuration, animated: false)
        cell.frame.size = cell.systemLayoutSizeFitting(CGSize(width: 414, height: 0))

        // THEN
        verify(matching: cell)
    }

    func testThatItRendersSoundCloudPlaylistAttachment() {
        // GIVEN
        let attachment = LinkAttachment(type: .soundCloudPlaylist, title: "Artists To Watch 2019",
                                        permalink: URL(string: "https://soundcloud.com/playback/sets/2019-artists-to-watch")!,
                                        thumbnails: [], originalRange: NSRange(location: 0, length: 58))

        mockThumbnail.cacheIdentifier = #function
        let configuration = ConversationLinkAttachmentCell.Configuration(attachment: attachment, thumbnailResource: mockThumbnail)

        // WHEN
        let cell = ConversationLinkAttachmentCell()
        cell.configure(with: configuration, animated: false)
        cell.frame.size = cell.systemLayoutSizeFitting(CGSize(width: 414, height: 0))

        // THEN
        verify(matching: cell)
    }

}
