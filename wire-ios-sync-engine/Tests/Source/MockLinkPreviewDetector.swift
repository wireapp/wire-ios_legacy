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
import WireLinkPreview

class MockLinkPreviewDetector: LinkPreviewDetectorType {

    fileprivate let mockImageURL = URL(string: "http://reallifepic.com/s0m3cHucKN0rR1sp1C.jpg")!
    fileprivate let mockImageData: Data = Data(repeating: 0x41, count: 10)

    enum LinkPreviewURL: String {
        case article = "http://someurl.com/nopicture"
        case articleWithPicture = "http://someurl.com/magicpicture"
        case tweet = "http://twitter.com/jcvd/status/averybigtweetid"
        case tweetWithPicture = "http://twitter.com/jcvd/status/fullsplitbetweentruckspic"
    }

    func downloadLinkPreviews(inText text: String, excluding: [NSRange], completion: @escaping ([LinkMetadata]) -> Void) {
        guard let linkPreviewURL = LinkPreviewURL(rawValue: text) else { return completion([]) }

        completion([linkMetaData(linkPreviewURL)])
    }

    func linkMetaData(_ linkPreviewURL: LinkPreviewURL) -> LinkMetadata {

        switch linkPreviewURL {
        case .article:
            let buffer = LinkPreview(withOriginalURL: linkPreviewURL.rawValue,
                                     permanentURL: linkPreviewURL.rawValue,
                                     offset: 0,
                                     title: "ClickHole: You won't believe what THIS CAT can do!",
                                     summary: "Wasting your time",
                                     imageAsset: nil)

            let article = ArticleMetadata(protocolBuffer: buffer)

            return article
        case .articleWithPicture:
            let buffer = LinkPreview(withOriginalURL: linkPreviewURL.rawValue,
                                     permanentURL: linkPreviewURL.rawValue,
                                     offset: 0,
                                     title: "ClickHole: You won't believe what THIS CAT can do!",
                                     summary: "Wasting your time",
                                     imageAsset: randomAsset())

            let article = ArticleMetadata(protocolBuffer: buffer)
            article.imageData = [mockImageData]
            article.imageURLs = [mockImageURL]

            return article
        case .tweet:
            let buffer = LinkPreview(withOriginalURL: linkPreviewURL.rawValue,
                                     permanentURL: linkPreviewURL.rawValue,
                                     offset: 0,
                                     title: "1 + 1 = 1, or 11, a that's beautiful.",
                                     summary: nil,
                                     imageAsset: nil,
                                     tweet: Tweet(author: "Jean-Claude Van Damme", username: "JCVDG05U"))

            let tweet = TwitterStatusMetadata(protocolBuffer: buffer)

            return tweet
        case .tweetWithPicture:
            let buffer = LinkPreview(withOriginalURL: linkPreviewURL.rawValue,
                                     permanentURL: linkPreviewURL.rawValue,
                                     offset: 0,
                                     title: "1 + 1 = 1, or 11, a that's beautiful.",
                                     summary: nil,
                                     imageAsset: randomAsset(),
                                     tweet: Tweet(author: "Jean-Claude Van Damme", username: "JCVDG05U"))

            let twitterStatus = TwitterStatusMetadata(protocolBuffer: buffer)
            twitterStatus.imageData = [mockImageData]
            twitterStatus.imageURLs = [mockImageURL]

            return twitterStatus
        }

    }

    fileprivate func randomAsset() -> WireProtos.Asset {
        return WireProtos.Asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
    }
}
